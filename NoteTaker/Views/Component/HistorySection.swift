//
//  HistorySection.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct HistorySection: View {
    let history: [Transcript]
    let onSelect: (Transcript) -> Void
    let onDelete: (Transcript) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transcripts")
                    .font(.headline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(in: .rect(cornerRadius: 10))
                Spacer()
            }

            if history.isEmpty {
                Text("No transcripts saved yet. Recorded notes will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(history.enumerated()), id: \.element.id) { index, transcript in
                    if !transcript.displayText.isEmpty {
                        TranscriptRow(transcript: transcript, onDelete: onDelete)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(transcript)
                            }
                            .padding()
                            .background(Color.indigo.opacity(0.05))
                            .cornerRadius(8)
                            .glassEffect(in: .rect(cornerRadius: 8))
                        if index != history.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


//#Preview {
//    HistorySection()
//}
