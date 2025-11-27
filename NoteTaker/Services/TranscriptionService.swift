//
//  TranscriptionService.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import AVFoundation
import Combine
import Speech

enum TranscriptionError: LocalizedError {
    case permissionsDenied
    case recognizerUnavailable
    case audioEngineFailure(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .permissionsDenied:
            return "Speech recognition and microphone permissions are required."
        case .recognizerUnavailable:
            return "Speech recognizer is currently unavailable."
        case .audioEngineFailure(let message):
            return message
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

struct TranscriptionEvent {
    enum Kind {
        case partial(String)
        case final(String)
        case reset
        case interrupted
    }

    let kind: Kind
    let timestamp: Date

    init(kind: Kind, timestamp: Date = Date()) {
        self.kind = kind
        self.timestamp = timestamp
    }
}

protocol TranscriptionServicing: AnyObject {
    var events: AnyPublisher<TranscriptionEvent, Never> { get }
    var isRecording: Bool { get }
    var recordedAudioURL: URL? { get }
    func requestPermissions() async throws
    func start(locale: Locale, forceOnDevice: Bool) async throws
    func stop()
}

final class TranscriptionService: NSObject, TranscriptionServicing {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioFile: AVAudioFile?
    private(set) var lastRecordingURL: URL?
    private let audioSessionManager: AudioSessionManaging
    private let eventsSubject = PassthroughSubject<TranscriptionEvent, Never>()

    var events: AnyPublisher<TranscriptionEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    private(set) var isRecording: Bool = false
    var recordedAudioURL: URL? {
        lastRecordingURL
    }

    init(audioSessionManager: AudioSessionManaging = AudioSessionManager()) {
        self.audioSessionManager = audioSessionManager
        super.init()
        audioSessionManager.interruptionHandler = { [weak self] type in
            guard let self else { return }
            if type == .began {
                self.interruptRecording()
            }
        }
        audioSessionManager.routeChangeHandler = { [weak self] _ in
            self?.interruptRecording()
        }
    }

    func requestPermissions() async throws {
        let audioGranted: Bool
        if #available(iOS 17.0, *) {
            audioGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            audioGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus)
            }
        }

        guard audioGranted, status == .authorized else {
            throw TranscriptionError.permissionsDenied
        }
    }

    func start(locale: Locale = .current, forceOnDevice: Bool = false) async throws {
        guard !isRecording else { return }
        
        // Configure audio session with error handling
        do {
            try audioSessionManager.configureSession()
        } catch {
            throw TranscriptionError.audioEngineFailure("Failed to configure audio session: \(error.localizedDescription)")
        }

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }
        if forceOnDevice, !recognizer.supportsOnDeviceRecognition {
            throw TranscriptionError.recognizerUnavailable
        }
        speechRecognizer = recognizer

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation // Better for continuous speech
        if forceOnDevice, recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        let fileURL = makeRecordingURL()
        audioFile = try? AVAudioFile(forWriting: fileURL, settings: recordingFormat.settings)
        lastRecordingURL = fileURL

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.recognitionRequest?.append(buffer)
            try? self.audioFile?.write(from: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw TranscriptionError.audioEngineFailure(error.localizedDescription)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                let kind: TranscriptionEvent.Kind = result.isFinal ? .final(text) : .partial(text)
                eventsSubject.send(TranscriptionEvent(kind: kind))
            }
            if let error {
                let nsError = error as NSError
                let ignorableErrorCodes: Set<Int> = [203, 216, 301, 1100, 1101, 1110]
                
                if !ignorableErrorCodes.contains(nsError.code) {
                    self.eventsSubject.send(TranscriptionEvent(kind: .interrupted))
                    self.stop(reset: false)
                }
            }
        }

        isRecording = true
    }

    func stop() {
        stop(reset: true)
    }

    private func stop(reset: Bool) {
        guard isRecording else { return }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioSessionManager.deactivateSession()
        audioFile = nil
        isRecording = false
        if reset {
            eventsSubject.send(TranscriptionEvent(kind: .reset))
        }
    }

    private func interruptRecording() {
        guard isRecording else { return }
        eventsSubject.send(TranscriptionEvent(kind: .interrupted))
        stop()
    }

    private func makeRecordingURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Recordings", isDirectory: true)
        if let directory, !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let filename = "recording-\(UUID().uuidString).caf"
        return (directory ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(filename)
    }
}

