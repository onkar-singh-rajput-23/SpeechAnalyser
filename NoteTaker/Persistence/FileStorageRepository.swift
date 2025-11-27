//
//  FileStorageRepository.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import Foundation

final class FileStorageRepository: TranscriptRepositoryProtocol {
    private let fileManager = FileManager.default
    private let storageURL: URL
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsPath.appendingPathComponent("transcripts.json")
    }
    
    func fetchRecent(limit: Int = 10) throws -> [Transcript] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: storageURL)
        let transcripts = try JSONDecoder().decode([Transcript].self, from: data)
        return Array(transcripts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    func save(_ transcript: Transcript) throws {
        var transcripts = (try? fetchAll()) ?? []
        transcripts.append(transcript)
        try saveAll(transcripts)
    }
    
    func update(_ transcript: Transcript) throws {
        var transcripts = try fetchAll()
        
        if let index = transcripts.firstIndex(where: { $0.id == transcript.id }) {
            transcripts[index] = transcript
            try saveAll(transcripts)
        } else {
            try save(transcript)
        }
    }
    
    func delete(_ transcript: Transcript) throws {
        var transcripts = try fetchAll()
        transcripts.removeAll { $0.id == transcript.id }
        try saveAll(transcripts)
    }
    
    // MARK: - Private Helpers
    
    private func fetchAll() throws -> [Transcript] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: storageURL)
        return try JSONDecoder().decode([Transcript].self, from: data)
    }
    
    private func saveAll(_ transcripts: [Transcript]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(transcripts)
        try data.write(to: storageURL, options: .atomic)
    }
}


protocol TranscriptRepositoryProtocol {
    func fetchRecent(limit: Int) throws -> [Transcript]
    func save(_ transcript: Transcript) throws
    func update(_ transcript: Transcript) throws
    func delete(_ transcript: Transcript) throws
}
