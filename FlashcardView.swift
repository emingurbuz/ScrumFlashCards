//
//  FlashcardView.swift
//  Scrum FlashCards
//

import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    let index: Int
    let total: Int
    var onAnswer: ((Bool) -> Void)? = nil
    let onNext: () -> Void

    @State private var selected: String?

    private var isLast: Bool { index + 1 == total }

    var body: some View {
        VStack(spacing: 20) {
            progress
            cardFace
            optionsGrid
            nextButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
    }

    // MARK: - Progress

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Card \(index + 1) of \(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Label("Scrum", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.25))
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * progressRatio)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressRatio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(index + 1) / CGFloat(total)
    }

    // MARK: - Card

    private var cardFace: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FILL IN THE BLANK")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(.secondary)

            sentence
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let selected {
                HStack(spacing: 8) {
                    Image(systemName: selected == card.answer ? "checkmark.seal.fill" : "xmark.seal.fill")
                    Text(selected == card.answer ? "Correct!" : "Correct answer: \(card.answer)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(selected == card.answer ? Color.green : Color.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        )
    }

    private var sentence: Text {
        let blank = Text(blankText)
            .underline()
            .foregroundColor(blankColor)
            .fontWeight(.bold)

        if card.suffix.isEmpty {
            return Text("\(card.prompt) \(blank)")
        }
        return Text("\(card.prompt) \(blank) \(card.suffix)")
    }

    private var blankText: String {
        selected ?? "__________"
    }

    private var blankColor: Color {
        guard let selected else { return .secondary }
        return selected == card.answer ? .green : .red
    }

    // MARK: - Options

    private var optionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(card.options, id: \.self) { option in
                Button {
                    select(option)
                } label: {
                    OptionLabel(
                        text: option,
                        state: state(for: option)
                    )
                }
                .buttonStyle(.plain)
                .disabled(selected != nil)
            }
        }
    }

    private func state(for option: String) -> OptionLabel.State {
        guard let selected else { return .idle }
        if option == card.answer { return .correct }
        if option == selected { return .incorrect }
        return .dimmed
    }

    // MARK: - Next

    private var nextButton: some View {
        Button(action: advance) {
            HStack(spacing: 8) {
                Text(nextButtonLabel)
                if selected != nil {
                    Image(systemName: isLast ? "checkmark" : "arrow.right")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(selected == nil ? Color.white.opacity(0.4) : Color.white)
            )
            .foregroundStyle(selected == nil ? .white.opacity(0.7) : Color.indigo)
            .shadow(color: .black.opacity(selected == nil ? 0 : 0.15), radius: 8, y: 4)
        }
        .disabled(selected == nil)
        .padding(.top, 4)
    }

    private var nextButtonLabel: String {
        if selected == nil { return "Pick an answer" }
        return isLast ? "Finish" : "Next Card"
    }

    // MARK: - Actions

    private func select(_ option: String) {
        guard selected == nil else { return }
        selected = option
    }

    private func advance() {
        if let selected {
            onAnswer?(selected == card.answer)
        }
        self.selected = nil
        onNext()
    }
}

// MARK: - Option Label

private struct OptionLabel: View {
    enum State { case idle, correct, incorrect, dimmed }

    let text: String
    let state: State

    var body: some View {
        Text(text)
            .font(.callout.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1.5)
            )
            .foregroundStyle(foreground)
            .scaleEffect(state == .correct ? 1.03 : 1.0)
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }

    private var fill: Color {
        switch state {
        case .idle: return Color(.systemBackground)
        case .correct: return Color.green.opacity(0.18)
        case .incorrect: return Color.red.opacity(0.18)
        case .dimmed: return Color(.systemBackground).opacity(0.6)
        }
    }

    private var stroke: Color {
        switch state {
        case .idle: return Color.black.opacity(0.08)
        case .correct: return Color.green
        case .incorrect: return Color.red
        case .dimmed: return Color.black.opacity(0.05)
        }
    }

    private var foreground: Color {
        switch state {
        case .idle: return .primary
        case .correct: return .green
        case .incorrect: return .red
        case .dimmed: return .secondary
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.indigo, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        StatefulPreview()
    }
}

private struct StatefulPreview: View {
    @State private var index = 0
    private let cards = Flashcard.cards(in: .basic)

    var body: some View {
        FlashcardView(card: cards[index], index: index, total: cards.count) {
            index = (index + 1) % cards.count
        }
        .id(cards[index].id)
    }
}
