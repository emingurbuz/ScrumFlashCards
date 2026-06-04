//
//  Flashcard.swift
//  Scrum FlashCards
//

import Foundation

struct Flashcard: Identifiable, Equatable, Codable {
    let id: String
    let prompt: String
    let suffix: String
    let answer: String
    let distractors: [String]
    let level: Level
    /// Stable shuffled order of the answer + distractors, fixed for this instance's lifetime.
    let options: [String]

    init(id: String, prompt: String, suffix: String = "", answer: String, distractors: [String], level: Level) {
        self.id = id
        self.prompt = prompt
        self.suffix = suffix
        self.answer = answer
        self.distractors = distractors
        self.level = level
        self.options = ([answer] + distractors).shuffled()
    }

    private enum CodingKeys: String, CodingKey {
        case id, prompt, suffix, answer, distractors, level
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.prompt = try c.decode(String.self, forKey: .prompt)
        self.suffix = try c.decodeIfPresent(String.self, forKey: .suffix) ?? ""
        self.answer = try c.decode(String.self, forKey: .answer)
        self.distractors = try c.decode([String].self, forKey: .distractors)
        self.level = try c.decode(Level.self, forKey: .level)
        self.options = ([self.answer] + self.distractors).shuffled()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(prompt, forKey: .prompt)
        if !suffix.isEmpty { try c.encode(suffix, forKey: .suffix) }
        try c.encode(answer, forKey: .answer)
        try c.encode(distractors, forKey: .distractors)
        try c.encode(level, forKey: .level)
    }

    static func == (lhs: Flashcard, rhs: Flashcard) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Library

extension Flashcard {
    /// All cards loaded from the per-level JSON files in the app bundle. Cached after first access.
    static let all: [Flashcard] = loadAll()

    static func cards(in level: Level) -> [Flashcard] {
        all.filter { $0.level == level }
    }

    static func cards(matching ids: Set<String>) -> [Flashcard] {
        all.filter { ids.contains($0.id) }
    }

    private static func loadAll() -> [Flashcard] {
        let files = ["basic", "intermediate", "advanced"]
        var cards: [Flashcard] = []
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
                assertionFailure("Missing \(name).json in app bundle")
                continue
            }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([Flashcard].self, from: data)
                cards.append(contentsOf: decoded)
            } catch {
                assertionFailure("Failed to decode \(name).json: \(error)")
            }
        }
        return cards
    }
}
