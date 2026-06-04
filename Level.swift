//
//  Level.swift
//  Scrum FlashCards
//

import SwiftUI

enum Level: String, CaseIterable, Codable, Identifiable, Hashable {
    case basic, intermediate, advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: return "Basic"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var subtitle: String {
        switch self {
        case .basic: return "Roles, events, artifacts"
        case .intermediate: return "Empiricism & team dynamics"
        case .advanced: return "Scaling & edge cases"
        }
    }

    var iconName: String {
        switch self {
        case .basic: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "crown.fill"
        }
    }

    var accent: Color {
        switch self {
        case .basic: return Color(red: 0.30, green: 0.80, blue: 0.55)
        case .intermediate: return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .advanced: return Color(red: 0.60, green: 0.35, blue: 0.95)
        }
    }

    var order: Int {
        switch self {
        case .basic: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }

    /// Accuracy required to unlock the next level (exam-style gate).
    var passingPercentage: Double { 0.85 }

    var next: Level? {
        switch self {
        case .basic: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return nil
        }
    }
}
