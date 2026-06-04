//
//  ContentView.swift
//  Scrum FlashCards
//
//  Created by Emin Gürbüz on 3.06.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        LevelPickerView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CardProgress.self, LevelProgress.self], inMemory: true)
}
