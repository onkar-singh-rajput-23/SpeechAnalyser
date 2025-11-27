//
//  TextAnalyzer.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import Foundation
import NaturalLanguage
import AVFoundation
import Speech

protocol TextAnalyzing {
    func analyze(_ text: String) -> String
    func quickAnalyze(_ text: String) -> String
    func addPunctuation(_ text: String) -> String
    func fixCapitalization(_ text: String) -> String
    func detectLanguage(_ text: String) -> String?
}

@available(iOS 16.0, *)
final class TextAnalyzer: TextAnalyzing {
    private var transcriber: SFSpeechRecognizer?
    
    // MARK: - Main Analysis

    func analyze(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        var analyzedText = text
        analyzedText = addPunctuation(analyzedText)
        analyzedText = fixCapitalization(analyzedText)
        analyzedText = cleanupSpaces(analyzedText)
        
        return analyzedText
    }
    
    func quickAnalyze(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        var result = text
        result = cleanupSpaces(result)
        
        if let first = result.first, first.isLowercase {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }
        
        return result
    }
    
    func addPunctuation(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        var result = text
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var sentences: [String] = []
        var currentSentence = ""
        
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            
            if currentSentence.isEmpty {
                currentSentence = word
            } else {
                currentSentence += " " + word
            }
            
            if shouldEndSentence(word: word, tag: tag) {
                sentences.append(currentSentence)
                currentSentence = ""
            }
            
            return true
        }
        
        if !currentSentence.isEmpty {
            sentences.append(currentSentence)
        }
        
        if sentences.isEmpty {
            sentences = [text]
        }
        
        let processedSentences = sentences.map { sentence -> String in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            
            let lastChar = trimmed.last
            if lastChar == "." || lastChar == "!" || lastChar == "?" {
                return trimmed
            }
            
            if isQuestion(trimmed) {
                return trimmed + "?"
            }
            
            if isExclamation(trimmed) {
                return trimmed + "!"
            }
            
            return trimmed + "."
        }
        
        result = processedSentences.joined(separator: " ")
        return result
    }
    
    func fixCapitalization(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        var result = ""
        var capitalizeNext = true
        
        for char in text {
            if capitalizeNext && char.isLetter {
                result.append(char.uppercased())
                capitalizeNext = false
            } else {
                result.append(char)
            }
            
            if char == "." || char == "!" || char == "?" {
                capitalizeNext = true
            }
        }
        
        return result
    }
    
    func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return nil
        }
        
        return language.rawValue
    }

    // MARK: - Private Helpers

    private func cleanupSpaces(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        result = result.replacingOccurrences(of: " +([.,!?])", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "([.,!?])([A-Za-z])", with: "$1 $2", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func shouldEndSentence(word: String, tag: NLTag?) -> Bool {
        let lowercased = word.lowercased()
        let sentenceEnders = ["yes", "no", "okay", "ok", "thanks", "thank you", "goodbye", "bye", "please"]
        
        return sentenceEnders.contains(lowercased)
    }
    
    private func isQuestion(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let questionWords = ["who", "what", "when", "where", "why", "how", "which", "whose", "whom", "can", "could", "would", "should", "is", "are", "do", "does", "did"]
        
        return questionWords.contains(where: { lowercased.hasPrefix($0 + " ") })
    }
    
    private func isExclamation(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let exclamationWords = ["wow", "amazing", "awesome", "great", "fantastic", "excellent", "wonderful", "terrible", "horrible", "stop", "help", "hurry", "wait"]
        
        return exclamationWords.contains(where: { lowercased.contains($0) })
    }
}

