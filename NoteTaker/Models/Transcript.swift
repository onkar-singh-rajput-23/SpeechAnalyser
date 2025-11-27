//
//  Transcript.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import Foundation

struct Transcript: Identifiable, Equatable, Codable {
    let id: UUID
    var originalText: String
    var editedText: String
    var createdAt: Date
    var updatedAt: Date
    var metadata: RecordingMetadata

    init(
        id: UUID = UUID(),
        originalText: String,
        editedText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: RecordingMetadata
    ) {
        self.id = id
        self.originalText = originalText
        self.editedText = editedText ?? originalText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }

    var isEdited: Bool {
        originalText != editedText
    }

    var displayText: String {
        editedText
    }
}

struct RecordingMetadata: Equatable, Codable {
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var audioFileURL: URL?
    var localeIdentifier: String
    var usedOnDeviceRecognition: Bool

    static func makePlaceholder() -> RecordingMetadata {
        RecordingMetadata(
            startTime: Date(),
            endTime: Date(),
            duration: 0,
            audioFileURL: nil,
            localeIdentifier: Locale.current.identifier,
            usedOnDeviceRecognition: false
        )
    }
}

