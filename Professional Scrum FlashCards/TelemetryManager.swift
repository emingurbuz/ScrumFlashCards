import Foundation
import TelemetryClient
import FirebaseAnalytics // Added FirebaseAnalytics

/// A centralized manager to handle analytics signals using TelemetryDeck and Firebase.
class TelemetryManager {
    static let shared = TelemetryManager()
    
    private init() {}
    
    /// Initializes the TelemetryDeck SDK with the provided App ID.
    static func initialize() {
        var configuration = TelemetryManagerConfiguration(appID: "17D35C06-29E5-48FB-8810-4EFF294E9520")
        
        #if DEBUG
        configuration.testMode = true
        #else
        configuration.testMode = false
        #endif
        
        TelemetryDeck.initialize(config: configuration)
        print("[Telemetry] Initialized with App ID: 17D35C06-29E5-48FB-8810-4EFF294E9520 | Test Mode: \(configuration.testMode)")
    }
    
    /// Sends a signal to both TelemetryDeck and Firebase Analytics.
    /// - Parameters:
    ///   - signalName: The name of the event (e.g., "session_started", "card_answered")
    ///   - metadata: Additional context for the event
    func send(signalName: String, metadata: [String: String] = [:]) {
        var updatedMetadata = metadata
        
        #if DEBUG
        updatedMetadata["isTestMode"] = "true"
        #endif
        
        // 1. Log to TelemetryDeck
        TelemetryDeck.signal(signalName, parameters: updatedMetadata)
        
        // 2. Log to Firebase Analytics
        Analytics.logEvent(signalName, parameters: updatedMetadata)
        
        // Console prints for debugging
        print("[Telemetry] Signal sent: \(signalName) | Metadata: \(updatedMetadata)")
        print("[Firebase] Event logged: \(signalName) | Metadata: \(updatedMetadata)")
    }
    
    // MARK: - Helper Methods for "Intelligent" Metrics
    
    func trackSessionStart(level: String) {
        send(signalName: "session_started", metadata: ["level": level])
    }
    
    func trackSessionEnd(level: String, duration: Double, correct: Int, total: Int, finished: Bool) {
        send(signalName: "session_ended", metadata: [
            "level": level,
            "duration": String(format: "%.0f", duration),
            "score": "\(correct)/\(total)",
            "percentage": total > 0 ? "\(Int(Double(correct)/Double(total)*100))" : "0",
            "completed": String(finished)
        ])
    }
    
    func trackCardAnswer(cardID: String, level: String, isCorrect: Bool, timeTaken: Double) {
        send(signalName: "card_answered", metadata: [
            "card_id": cardID,
            "level": level,
            "is_correct": String(isCorrect),
            "time_taken": String(format: "%.1f", timeTaken)
        ])
    }
    
    func trackLevelReset(level: String) {
        send(signalName: "level_reset", metadata: ["level": level])
    }
    
    func trackMasteryAchieved(cardID: String) {
        send(signalName: "card_mastered", metadata: ["card_id": cardID])
    }
}
