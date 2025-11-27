//
//  TranscriptEditor.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct TranscriptEditor: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @FocusState var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcript")
                    .padding(.horizontal,10)
                    .padding(.vertical,5)
                    .font(.headline)
                    .glassEffect()
                
                Spacer()
                    Button(viewModel.isEditing ? "Done" : "Tap to Edit") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.setEditing(!viewModel.isEditing)
                        }
                        editorFocused = viewModel.isEditing
                    }
                    .buttonStyle(.bordered)
                    .glassEffect()
                    .glassEffectTransition(.identity)
                
            }

            if viewModel.isEditing {
                TextEditor(text: $viewModel.editableText)
                    .focused($editorFocused)
                    .frame(minHeight: 200)
                    .cornerRadius(12)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.green)))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: viewModel.editableText) { _, newValue in
                        viewModel.updateEditedText(newValue)
                    }
            } else {
                Text(viewModel.liveText.isEmpty ? "Start recording to see your transcript here." : viewModel.liveText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.systemGray).opacity(0.05))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .glassEffect(in: .rect(cornerRadius: 16.0))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.setEditing(true)
                        }
                        editorFocused = true
                    }
            }

            if viewModel.isEditing {
                Button {
                    viewModel.persistChanges()
                    editorFocused = false
                } label: {
                    Label("Save Changes", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .glassEffect()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isEditing)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.gray.opacity(0.05))
        )
    }
}


//#Preview {
//    TranscriptEditor()
//}
