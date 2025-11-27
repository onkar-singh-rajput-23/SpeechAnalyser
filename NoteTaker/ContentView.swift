//
//  ContentView.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()

    var body: some View {
        TranscriptionView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
