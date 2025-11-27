//
//  RecordButton.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.accentColor)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                        .glassEffect(.regular)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .foregroundColor(.white)
                    .font(.title)
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}
//#Preview {
//    RecordButton()
//}
