//
//  TranscriptRow.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct TranscriptRow: View {
    let transcript: Transcript
    let onDelete: (Transcript) -> Void
    

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(transcript.displayText)
                .font(.subheadline)
                .lineLimit(3)
            HStack(spacing: 12) {
                Label("\(Int(transcript.metadata.duration))s", systemImage: "clock")
                    .font(.caption)
                    .padding(.horizontal,6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .glassEffect(.clear, in :.rect(cornerRadius: 10))

                if transcript.metadata.usedOnDeviceRecognition {
                    Label("On-Device", systemImage: "bolt.horizontal.circle")
                        .font(.caption)
                        .padding(.horizontal,6)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .glassEffect(.clear, in :.rect(cornerRadius: 10))
                }
                Text(transcript.createdAt, style: .date)
                    .font(.caption2)
                    .padding(.horizontal,6)
                    .padding(.vertical, 3)
                    .foregroundStyle(.secondary)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .glassEffect(.clear, in :.rect(cornerRadius: 10))
                
                Button {
                    onDelete(transcript)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .frame(width: 10, height: 10)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//#Preview {
//    TranscriptRow()
//}
