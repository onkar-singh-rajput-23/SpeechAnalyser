//
//  TranscriptionViewModel.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import Combine
import Foundation
import Speech

@MainActor
final class TranscriptionViewModel: ObservableObject {
    struct AlertContent: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var isRecording = false
    @Published var isEditing = false
    @Published var liveText: String = ""
    @Published var editableText: String = ""
    @Published var statusMessage: String = "Ready to record"
    @Published var history: [Transcript] = []
    @Published var alertContent: AlertContent?
    @Published var isRequestingPermissions = false
    @Published var useIntelligentAnalysis: Bool = true
    @Published var selectedTranscript: Transcript?

    private let transcriptionService: TranscriptionServicing
    private let repository: TranscriptRepositoryProtocol
    private let textAnalyzer: TextAnalyzing
    private let localeProvider: () -> Locale
    private var cancellables = Set<AnyCancellable>()
    private var currentMetadata: RecordingMetadata = .makePlaceholder()
    private var currentStartDate: Date?
    private var currentTranscriptID: UUID?
    private var accumulatedSegments: [String] = []
    private var currentSegment: String = ""
    private var lastPartialText: String = ""
    private var pauseDetectionTimer: Timer?

    init(
        transcriptionService: TranscriptionServicing? = nil,
        repository: TranscriptRepositoryProtocol? = nil,
        textAnalyzer: TextAnalyzing? = nil,
        localeProvider: @escaping () -> Locale = { Locale.current },
        autoStart: Bool = true
    ) {
        self.transcriptionService = transcriptionService ?? TranscriptionService()
        self.repository = repository ?? FileStorageRepository()
        self.textAnalyzer = textAnalyzer ?? TextAnalyzer()
        self.localeProvider = localeProvider
        bindEvents()
        if autoStart {
            Task {
                await requestPermissionsIfNeeded()
                await loadHistory()
            }
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func setEditing(_ editing: Bool) {
        isEditing = editing
        if !editing {
            editableText = liveText
        }
    }

    func updateEditedText(_ text: String) {
        editableText = text
    }

    func persistChanges() {
        guard !liveText.isEmpty else { return }
        let metadata = currentMetadata
        let transcript = Transcript(
            id: currentTranscriptID ?? UUID(),
            originalText: liveText,
            editedText: editableText,
            createdAt: metadata.startTime,
            updatedAt: Date(),
            metadata: metadata
        )
        do {
            if let existingIndex = history.firstIndex(where: { $0.id == transcript.id }) {
                try repository.update(transcript)
                history[existingIndex] = transcript
            } else {
                try repository.save(transcript)
                history.insert(transcript, at: 0)
            }
            currentTranscriptID = transcript.id
        } catch {
            alertContent = AlertContent(title: "Save Failed", message: error.localizedDescription)
        }
    }

    func refreshHistory() {
        Task {
            await loadHistory()
        }
    }
    
    func selectTranscript(_ transcript: Transcript) {
        selectedTranscript = transcript
    }
    
    func dismissTranscript() {
        selectedTranscript = nil
    }
    
    func updateTranscriptText(_ transcript: Transcript, newText: String) {
        var updatedTranscript = transcript
        updatedTranscript.editedText = newText
        updatedTranscript.updatedAt = Date()
        
        do {
            try repository.update(updatedTranscript)
            
            if let index = history.firstIndex(where: { $0.id == transcript.id }) {
                history[index] = updatedTranscript
            }
            
            selectedTranscript = updatedTranscript
        } catch {
            alertContent = AlertContent(
                title: "Update Failed",
                message: error.localizedDescription
            )
        }
    }
    
    func deleteTranscript(_ transcript: Transcript) {
        do {
            try repository.delete(transcript)
            history.removeAll { $0.id == transcript.id }
            
            if selectedTranscript?.id == transcript.id {
                selectedTranscript = nil
            }
        } catch {
            alertContent = AlertContent(
                title: "Delete Failed",
                message: error.localizedDescription
            )
        }
    }

    private func startRecording() {
        statusMessage = "Preparing..."
        accumulatedSegments = []
        currentSegment = ""
        lastPartialText = ""
        liveText = ""
        editableText = ""
        pauseDetectionTimer?.invalidate()
        pauseDetectionTimer = nil
        
        Task {
            do {
                if !isRequestingPermissions {
                    isRequestingPermissions = true
                    defer { isRequestingPermissions = false }
                    try await transcriptionService.requestPermissions()
                }
                currentStartDate = Date()
                currentTranscriptID = UUID()
                try await transcriptionService.start(locale: localeProvider(), forceOnDevice: true)
                await MainActor.run {
                    statusMessage = "Recording (On-Device)"
                    isRecording = true
                }
            } catch {
                handleError(error)
            }
        }
    }

    private func stopRecording() {
        transcriptionService.stop()
        isRecording = false
        
        pauseDetectionTimer?.invalidate()
        pauseDetectionTimer = nil
        
        if !currentSegment.isEmpty && !accumulatedSegments.contains(currentSegment) {
            accumulatedSegments.append(currentSegment)
        }
        
        statusMessage = "Processing transcript..."
        
        let finalText = accumulatedSegments.joined(separator: " ")
        liveText = finalText
        
        if !finalText.isEmpty && !isEditing {
            statusMessage = "Analyzing text..."
            let analyzedText = useIntelligentAnalysis ? textAnalyzer.analyze(finalText) : finalText
            editableText = analyzedText
        }
        
        finalizeTranscriptIfNeeded()
    }
    
    private func handlePauseDetected() {
        guard isRecording else { return }
        
        if !currentSegment.isEmpty && !accumulatedSegments.contains(currentSegment) {
            accumulatedSegments.append(currentSegment)
            
            let displayText = buildDisplayText()
            liveText = displayText
            
            if !isEditing && useIntelligentAnalysis {
                let analyzedText = textAnalyzer.analyze(displayText)
                editableText = analyzedText
            }
        }
    }

    private func bindEvents() {
        transcriptionService.events
            .sink { [weak self] event in
                guard let self else { return }
                Task { @MainActor in
                    switch event.kind {
                    case .partial(let text):
                        self.handlePartial(text)
                    case .final(let text):
                        self.handleFinal(text)
                    case .reset:
                        self.isRecording = false
                        self.statusMessage = "Ready to record"
                    case .interrupted:
                        self.handleInterruption()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func handlePartial(_ text: String) {
        if !lastPartialText.isEmpty && 
           !text.isEmpty &&
           text.count < lastPartialText.count / 2 &&
           !lastPartialText.lowercased().starts(with: text.lowercased()) {
            if !lastPartialText.isEmpty && !accumulatedSegments.contains(lastPartialText) {
                accumulatedSegments.append(lastPartialText)
            }
        }
        
        lastPartialText = text
        currentSegment = text
        
        pauseDetectionTimer?.invalidate()
        pauseDetectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handlePauseDetected()
            }
        }
        
        let displayText = buildDisplayText()
        liveText = displayText
        
        if !isEditing {
            if useIntelligentAnalysis {
                let analyzedText = textAnalyzer.analyze(displayText)
                editableText = analyzedText
            } else {
                editableText = displayText
            }
        }
        statusMessage = "Listening..."
    }

    private func handleFinal(_ text: String) {
        if !text.isEmpty && (accumulatedSegments.isEmpty || accumulatedSegments.last != text) {
            accumulatedSegments.append(text)
        }
        
        currentSegment = ""
        
        let displayText = buildDisplayText()
        liveText = displayText
        
        if !isEditing {
            if useIntelligentAnalysis {
                let analyzedText = textAnalyzer.analyze(displayText)
                editableText = analyzedText
            } else {
                editableText = displayText
            }
        }
        
        statusMessage = "Listening..."
    }

    private func finalizeTranscriptIfNeeded() {
        guard !liveText.isEmpty else {
            statusMessage = "Ready to record"
            return
        }

        let endDate = Date()
        let startDate = currentStartDate ?? endDate
        currentMetadata = RecordingMetadata(
            startTime: startDate,
            endTime: endDate,
            duration: endDate.timeIntervalSince(startDate),
            audioFileURL: transcriptionService.recordedAudioURL,
            localeIdentifier: localeProvider().identifier,
            usedOnDeviceRecognition: true
        )

        persistChanges()
        statusMessage = "Transcript saved"
        refreshHistory()
    }

    private func handleInterruption() {
        isRecording = false
        
        if !currentSegment.isEmpty {
            accumulatedSegments.append(currentSegment)
        }
        
        let finalText = accumulatedSegments.joined(separator: " ")
        liveText = finalText
        
        if !finalText.isEmpty && !isEditing {
            statusMessage = "Analyzing interrupted text..."
            let analyzedText = useIntelligentAnalysis ? textAnalyzer.analyze(finalText) : finalText
            editableText = analyzedText
            finalizeTranscriptIfNeeded()
        }
        
        statusMessage = "Recording interrupted"
        alertContent = AlertContent(
            title: "Recording Interrupted",
            message: "Your transcript has been saved. Tap record to continue."
        )
    }

    private func handleError(_ error: Error) {
        isRecording = false
        statusMessage = "Error: \(error.localizedDescription)"
        alertContent = AlertContent(title: "Error", message: error.localizedDescription)
    }

    private func requestPermissionsIfNeeded() async {
        do {
            try await transcriptionService.requestPermissions()
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    private func buildDisplayText() -> String {
        var parts: [String] = []
        parts.append(contentsOf: accumulatedSegments)
        
        if !currentSegment.isEmpty {
            parts.append(currentSegment)
        }
        
        return parts.joined(separator: " ")
    }

    private func loadHistory() async {
        do {
            let items = try repository.fetchRecent(limit: 25)
            await MainActor.run {
                self.history = items
            }
        } catch {
            await MainActor.run {
                self.alertContent = AlertContent(title: "Unable to load history", message: error.localizedDescription)
            }
        }
    }

}

