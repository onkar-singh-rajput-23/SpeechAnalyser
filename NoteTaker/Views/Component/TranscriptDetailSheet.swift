//
//  TranscriptDetailSheet.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct TranscriptDetailSheet: View {
    let transcript: Transcript
    let onSave: (String) -> Void
    let onDismiss: () -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedText: String
    @FocusState private var isTextEditorFocused: Bool
    
    init(transcript: Transcript, onSave: @escaping (String) -> Void, onDismiss: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.transcript = transcript
        self.onSave = onSave
        self.onDismiss = onDismiss
        _editedText = State(initialValue: transcript.displayText)
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Metadata Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Duration", systemImage: "clock")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .glassEffect()
                            Spacer()
                            Text("\(Int(transcript.metadata.duration))s")
                                .foregroundStyle(.secondary)
                                .padding(4)
                                .glassEffect()
                        }
                        
                        HStack {
                            Label("Created", systemImage: "calendar")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .glassEffect()
                            Spacer()
                            Text(transcript.createdAt, style: .date)
                                .foregroundStyle(.secondary)
                                .padding(4)
                                .glassEffect()
                        }
                        
                        
                        HStack {
                            Label("Time", systemImage: "clock.fill")
                                .glassEffect()
                            Spacer()
                            Text(transcript.createdAt, style: .time)
                                .foregroundStyle(.secondary)
                                .padding(5)
                                .glassEffect()
                        }
                        
                        
                        if transcript.metadata.usedOnDeviceRecognition {
                            HStack {
                                Label("Processing", systemImage: "bolt.horizontal.circle")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .glassEffect()
                                Spacer()
                                Text("On-Device")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .glassEffect()
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Transcript Text
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("Delete"){
                                onDelete()
                                onDismiss()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .glassEffect()
                            
                            Spacer()
                            
                            Text("Transcript")
                                .font(.headline)
                                .padding(.horizontal,10)
                                .padding(.vertical,5)
                                .glassEffect()

                            Spacer()
                            Button(isEditing ? "Save Changes" : "Edit") {
                                if isEditing {
                                    // Save changes
                                    onSave(editedText)
                                    isTextEditorFocused = false
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isEditing.toggle()
                                }
                                
                                if isEditing {
                                    isTextEditorFocused = true
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(isEditing ? .green : .accentColor)
                            .glassEffect()

                        }
                        
                        if isEditing {
                            TextEditor(text: $editedText)
                                .focused($isTextEditorFocused)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            Text(editedText)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        if isEditing && editedText != transcript.displayText {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Tap 'Save Changes' to update the transcript")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isEditing)
                }
                .padding()
            }
            .navigationTitle("Transcript Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
//#Preview {
//    TranscriptDetailSheet()
//}
