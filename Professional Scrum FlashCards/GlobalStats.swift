//
//  GlobalStats.swift
//  Scrum FlashCards
//

import Foundation
import SwiftData

@Model
final class GlobalStats {
    var totalSessionsCount: Int
    var totalSecondsPracticed: Double
    var lastOpenedDate: Date
    var totalResetsCount: Int

    init(totalSessionsCount: Int = 0, totalSecondsPracticed: Double = 0, lastOpenedDate: Date = .now, totalResetsCount: Int = 0) {
        self.totalSessionsCount = totalSessionsCount
        self.totalSecondsPracticed = totalSecondsPracticed
        self.lastOpenedDate = lastOpenedDate
        self.totalResetsCount = totalResetsCount
    }
}
