//
//  Scrum_FlashCardsApp.swift
//  Scrum FlashCards
//
//  Created by Emin Gürbüz on 3.06.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore // Added FirebaseCore

@main
struct Scrum_FlashCardsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize TelemetryDeck
        TelemetryManager.initialize()
        
        do {
            container = try ModelContainer(for: CardProgress.self, LevelProgress.self, GlobalStats.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                recordSession()
            }
        }
    }
    
    @MainActor
    private func recordSession() {
        ProgressStore(context: container.mainContext).recordAppOpen()
    }
}
