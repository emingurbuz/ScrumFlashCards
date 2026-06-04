//
//  Scrum_FlashCardsApp.swift
//  Scrum FlashCards
//
//  Created by Emin Gürbüz on 3.06.2026.
//

import SwiftUI
import SwiftData

@main
struct Scrum_FlashCardsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CardProgress.self, LevelProgress.self])
    }
}
