//
//  ProgressStore.swift
//  Scrum FlashCards
//

import Foundation
import SwiftData

@MainActor
struct ProgressStore {
    let context: ModelContext

    // MARK: - Card progress

    func cardProgress(for cardID: String) -> CardProgress {
        var fd = FetchDescriptor<CardProgress>(predicate: #Predicate { $0.cardID == cardID })
        fd.fetchLimit = 1
        if let existing = (try? context.fetch(fd))?.first {
            return existing
        }
        let new = CardProgress(cardID: cardID)
        context.insert(new)
        return new
    }

    @discardableResult
    func recordAnswer(card: Flashcard, correct: Bool) -> CardProgress {
        let progress = cardProgress(for: card.id)
        let wasMastered = progress.isMastered
        progress.record(correct: correct)
        
        // Intelligent Metric: Mastery track
        if !wasMastered && progress.isMastered {
            TelemetryManager.shared.trackMasteryAchieved(cardID: card.id)
        }
        
        return progress
    }

    // MARK: - Level progress

    func levelProgress(for level: Level) -> LevelProgress {
        let raw = level.rawValue
        var fd = FetchDescriptor<LevelProgress>(predicate: #Predicate { $0.levelRaw == raw })
        fd.fetchLimit = 1
        if let existing = (try? context.fetch(fd))?.first {
            return existing
        }
        // Basic is unlocked by default; everything else starts locked.
        let new = LevelProgress(level: level, isUnlocked: level == .basic)
        context.insert(new)
        return new
    }

    /// Records the result of finishing a full level run. Unlocks the next level
    /// if accuracy meets the level's passing percentage (exam-style gate).
    func finishLevelAttempt(level: Level, correct: Int, total: Int) {
        let lp = levelProgress(for: level)
        lp.recordAttempt(correct: correct, total: total)
        guard total > 0 else { return }
        let pct = Double(correct) / Double(total)
        if pct >= level.passingPercentage, let next = level.next {
            let nextLp = levelProgress(for: next)
            if !nextLp.isUnlocked {
                nextLp.isUnlocked = true
                TelemetryManager.shared.send(signalName: "level_unlocked", metadata: ["level": next.rawValue])
            }
        }
    }

    func ensureAllLevelProgressExists() {
        for level in Level.allCases {
            _ = levelProgress(for: level)
        }
        _ = globalStats()
    }

    /// Wipes all per-card and per-level progress, then re-seeds defaults
    /// (Basic unlocked, everything else locked).
    func resetAllProgress() {
        try? context.delete(model: CardProgress.self)
        try? context.delete(model: LevelProgress.self)
        let stats = globalStats()
        stats.totalResetsCount += 1
        ensureAllLevelProgressExists()
        TelemetryManager.shared.trackLevelReset(level: "all")
    }

    /// Resets a single level: clears its attempt history and any in-progress run,
    /// and removes per-card history for the cards in this level. Does NOT relock
    /// later levels that the user has already unlocked.
    func resetLevel(_ level: Level) {
        let lp = levelProgress(for: level)
        lp.bestPercentage = 0
        lp.lastAttemptCorrect = 0
        lp.lastAttemptTotal = 0
        lp.attemptsCount = 0
        lp.clearAttempt()

        let levelCardIDs = Set(Flashcard.cards(in: level).map(\.id))
        if let allCardProgress = try? context.fetch(FetchDescriptor<CardProgress>()) {
            for cp in allCardProgress where levelCardIDs.contains(cp.cardID) {
                context.delete(cp)
            }
        }
        
        let stats = globalStats()
        stats.totalResetsCount += 1
        TelemetryManager.shared.trackLevelReset(level: level.rawValue)
    }

    // MARK: - Review

    /// Card IDs that the learner has answered wrong at least once and hasn't yet re-mastered.
    func cardIDsNeedingReview() -> [String] {
        let fd = FetchDescriptor<CardProgress>(
            predicate: #Predicate { $0.wrongCount > 0 && $0.consecutiveCorrect < 3 },
            sortBy: [
                SortDescriptor(\.wrongCount, order: .reverse),
                SortDescriptor(\.lastAnsweredAt)
            ]
        )
        return (try? context.fetch(fd))?.map(\.cardID) ?? []
    }

    // MARK: - Global Stats

    func globalStats() -> GlobalStats {
        var fd = FetchDescriptor<GlobalStats>()
        fd.fetchLimit = 1
        if let existing = (try? context.fetch(fd))?.first {
            return existing
        }
        let new = GlobalStats()
        context.insert(new)
        return new
    }

    func recordAppOpen() {
        let stats = globalStats()
        stats.totalSessionsCount += 1
        stats.lastOpenedDate = .now
        TelemetryManager.shared.send(signalName: "app_open")
    }

    func addPracticeTime(_ seconds: Double) {
        let stats = globalStats()
        stats.totalSecondsPracticed += seconds
    }
}
