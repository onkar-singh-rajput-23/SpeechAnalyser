//
//  TranscriptionView.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct TranscriptionView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @FocusState private var editorFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        RecordingBanner(viewModel: viewModel)
                        TranscriptEditor(viewModel: viewModel, editorFocused: _editorFocused)
                        HistorySection(history: viewModel.history, onSelect: { transcript in
                            viewModel.selectTranscript(transcript)
                        }, onDelete: { transcript in
                            viewModel.deleteTranscript(transcript)
                        })
                    }
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                RecordButton(isRecording: viewModel.isRecording) {
                    viewModel.toggleRecording()
                    viewModel.isEditing = false
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 10)
            .navigationTitle("NoteTaker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Toggle(isOn: $viewModel.useIntelligentAnalysis) {
                            Image(systemName: viewModel.useIntelligentAnalysis ? "brain.head.profile" : "brain.head.profile")
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                        .accessibilityLabel("Intelligent text analysis")
                        
                        Button {
                            viewModel.refreshHistory()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Refresh transcripts")
                    }
                }
            }
        }
        .alert(item: $viewModel.alertContent) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(item: $viewModel.selectedTranscript) { transcript in
            TranscriptDetailSheet(
                transcript: transcript,
                onSave: { updatedText in
                    viewModel.updateTranscriptText(transcript, newText: updatedText)
                },
                onDismiss: {
                    viewModel.dismissTranscript()
                },
                onDelete: {
                    viewModel.deleteTranscript(transcript)
                }
            )
        }
    }
}













