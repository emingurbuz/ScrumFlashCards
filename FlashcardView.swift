//
//  FlashcardView.swift
//  Scrum FlashCards
//

import SwiftUI
import SwiftData

struct FlashcardView: View {
    let card: Flashcard
    let index: Int
    let total: Int
    let correctCount: Int
    let incorrectCount: Int
    let isMastered: Bool
    var mode: Mode = .learning
    var onAnswer: ((Bool) -> Void)? = nil
    let onNext: () -> Void

    @State private var selected: String?
    @State private var showXPEffect = false

    private var answerResult: Bool? {
        guard let selected else { return nil }
        return selected == card.answer
    }

    private var isLast: Bool { index + 1 == total }

    enum Mode: String {
        case learning = "LEARNING"
        case reviewing = "REVIEWING"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottom) {
                    physicalCard
                    
                    if selected != nil {
                        Button(action: advance) {
                            HStack(spacing: 8) {
                                Text("Tap for the next card")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(card.level.accent)
                                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
    }


    // MARK: - Physical Card

    private var physicalCard: some View {
        VStack(alignment: .center, spacing: 0) {
            // Header inside card
            HStack {
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: mode == .reviewing ? "arrow.clockwise" : "book.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(mode.rawValue)
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.15)))
                .foregroundStyle(.white)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            // Main Content Area
            VStack(spacing: 12) {
                progress
                cardFace
            }
            .padding(.top, 10)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            
            // Quiz Section
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                        Text("What is the correct answer?")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    
                    optionsGrid
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Background glow on answer
                if let result = answerResult {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(result ? Color.green : Color.red)
                        .opacity(0.12)
                        .blur(radius: 20)
                }

                // Blur background simulation - using a darker translucent background
                RoundedRectangle(cornerRadius: 40)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(card.level.accent.opacity(0.15))
                    )
                
                RoundedRectangle(cornerRadius: 40)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onTapGesture {
            if selected != nil {
                advance()
            }
        }
    }

    // MARK: - Progress

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card \(index + 1) of \(total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    HStack(spacing: 12) {
                        Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Label("\(incorrectCount)", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.15)))
                }
                
                Spacer()
                
                Label("Scrum", systemImage: isMastered ? "checkmark.seal.fill" : "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isMastered ? .yellow : .white.opacity(0.9))
                    .help(isMastered ? "Mastered" : "")
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.25))
                    
                    let width = geo.size.width * progressRatio
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: width)
                        .shadow(color: .white.opacity(0.5), radius: 4, x: 0, y: 0)
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
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption2)
                    Text("Question")
                        .font(.caption.weight(.heavy))
                        .tracking(2)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.orange.opacity(0.8))
            }

            sentence
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 80, alignment: .topLeading)

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
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                .blendMode(.overlay)
        )
    }

    private var sentence: Text {
        let suffix = card.suffix.isEmpty ? "" : " \(card.suffix)"
        let masteredIcon = Text(" \(Image(systemName: "checkmark.seal.fill"))")
            .baselineOffset(-1)
            .foregroundColor(.yellow)
        
        return Text("\(card.prompt) \(Text(blankText).underline().foregroundColor(blankColor).fontWeight(.bold))\(suffix)\(isMastered ? masteredIcon : Text(""))")
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
        VStack(spacing: 12) {
            let options = card.options
            ForEach(0..<options.count, id: \.self) { i in
                let option = options[i]
                Button {
                    select(option)
                } label: {
                    OptionLabel(
                        index: i,
                        text: option,
                        state: state(for: option)
                    )
                }
                .buttonStyle(.plain)
                .disabled(selected != nil)
                .overlay {
                    if showXPEffect && option == card.answer {
                        Text("+1 XP")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                            .offset(y: -40)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                }
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
                    .fill(selected == nil ? Color.white.opacity(0.15) : Color.white)
            )
            .foregroundStyle(selected == nil ? .white.opacity(0.5) : Color(red: 0.00, green: 0.31, blue: 0.48))
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(selected == nil ? 0.3 : 0), lineWidth: 1)
            )
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
        
        let isCorrect = option == card.answer
        if isCorrect {
            SoundManager.shared.playCorrect()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showXPEffect = true
                onAnswer?(true)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showXPEffect = false
                }
            }
        } else {
            SoundManager.shared.playIncorrect()
            onAnswer?(false)
        }
    }

    private func advance() {
        self.selected = nil
        onNext()
    }
}

// MARK: - Option Label

private struct OptionLabel: View {
    enum State { case idle, correct, incorrect, dimmed }

    let index: Int
    let text: String
    let state: State

    private var letter: String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return index < letters.count ? letters[index] : "?"
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(letter)
                .font(.caption.weight(.bold))
                .foregroundStyle(state == .dimmed ? .white.opacity(0.3) : .white.opacity(0.6))
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .strokeBorder(state == .dimmed ? .white.opacity(0.15) : .white.opacity(0.3), lineWidth: 1)
                )
            
            Text(text)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if state == .correct {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
            } else if state == .incorrect {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(fill)
        )
        .foregroundStyle(foreground)
        .scaleEffect(state == .correct ? 1.02 : 1.0)
    }

    private var fill: Color {
        switch state {
        case .idle: return .white.opacity(0.3)
        case .correct: return Color.green.opacity(0.5)
        case .incorrect: return Color.red.opacity(0.5)
        case .dimmed: return .white.opacity(0.15)
        }
    }

    private var foreground: Color {
        switch state {
        case .idle: return .white
        case .correct: return .white
        case .incorrect: return .white
        case .dimmed: return .white.opacity(0.5)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.00, green: 0.31, blue: 0.48), Color(red: 0.00, green: 0.59, blue: 0.65)],
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
        FlashcardView(
            card: cards[index],
            index: index,
            total: cards.count,
            correctCount: 0,
            incorrectCount: 0,
            isMastered: false
        ) {
            index = (index + 1) % cards.count
        }
        .id(cards[index].id)
    }
}
