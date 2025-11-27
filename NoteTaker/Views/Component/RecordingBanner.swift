//
//  RecordingBanner.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

 struct RecordingBanner: View {
    @ObservedObject var viewModel: TranscriptionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(viewModel.isRecording ? "Recording" : "", systemImage: viewModel.isRecording ? "waveform" : "pause.circle")
                    .font(.headline)
                    .foregroundColor(viewModel.isRecording ? .red : .accentColor)
                    .glassEffect(.identity, in: RoundedRectangle(cornerRadius: 10.0))
                Spacer()
                if viewModel.useIntelligentAnalysis {
                    Label("AI Analysis", systemImage: "brain.head.profile")
                        .font(.caption)
                        .padding(6)
                        .background(Color.purple.opacity(0.15), in: Capsule())
                        .foregroundColor(.purple)
                        .glassEffect()
                }
                Label("On-Device", systemImage: "bolt.horizontal.circle.fill")
                    .font(.caption)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .glassEffect()
            }
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.08))
        )
    }
}
#Preview {
//    RecordingBanner()
}
