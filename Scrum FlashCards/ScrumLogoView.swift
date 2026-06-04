//
//  ScrumLogoView.swift
//  Scrum FlashCards
//

import SwiftUI

struct ScrumLogoView: View {
    var size: CGFloat = 72
    var animated: Bool = true

    @State private var rotation: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            badge
            sprintLoop
            cardStack
            sparkles
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animated else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: - Badge background

    private var badge: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.45, green: 0.30, blue: 0.95),
                        Color(red: 0.85, green: 0.30, blue: 0.75),
                        Color(red: 1.00, green: 0.50, blue: 0.50)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: size * 0.015)
            )
            .shadow(color: .black.opacity(0.25), radius: size * 0.12, x: 0, y: size * 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.35), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.7
                        )
                    )
                    .blendMode(.plusLighter)
            )
    }

    // MARK: - Sprint loop (circular dashed arrow)

    private var sprintLoop: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.82)
                .stroke(
                    .white.opacity(0.95),
                    style: StrokeStyle(
                        lineWidth: size * 0.045,
                        lineCap: .round,
                        dash: [size * 0.06, size * 0.08]
                    )
                )
                .frame(width: size * 0.82, height: size * 0.82)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .white.opacity(0.4), radius: size * 0.04)

            // Arrowhead at the leading edge of the trim
            Image(systemName: "arrowtriangle.right.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.41)
                .rotationEffect(.degrees(-65), anchor: .center)
                .rotationEffect(.degrees(rotation))
        }
    }

    // MARK: - Card stack (the flashcards)

    private var cardStack: some View {
        ZStack {
            miniCard(angle: -14, offset: -size * 0.06, opacity: 0.55)
            miniCard(angle: 0, offset: 0, opacity: 0.85)
            miniCard(angle: 14, offset: size * 0.06, opacity: 1.0)
                .overlay(
                    Image(systemName: "bolt.fill")
                        .font(.system(size: size * 0.18, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
        .scaleEffect(pulse ? 1.04 : 1.0)
    }

    private func miniCard(angle: Double, offset: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
            .fill(Color.white.opacity(opacity))
            .frame(width: size * 0.42, height: size * 0.30)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                    .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: size * 0.04, y: size * 0.015)
            .rotationEffect(.degrees(angle))
            .offset(x: offset)
    }

    // MARK: - Sparkles

    private var sparkles: some View {
        ZStack {
            sparkle(x: size * 0.32, y: -size * 0.34, scale: 0.16)
            sparkle(x: -size * 0.36, y: size * 0.30, scale: 0.12)
            sparkle(x: size * 0.38, y: size * 0.34, scale: 0.10)
        }
        .opacity(pulse ? 1.0 : 0.4)
    }

    private func sparkle(x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: size * scale, height: size * scale)
            .offset(x: x, y: y)
            .shadow(color: .white.opacity(0.8), radius: size * 0.03)
    }
}

struct ScrumWordmarkView: View {
    var body: some View {
        VStack(spacing: 12) {
            ScrumLogoView(size: 88)
            VStack(spacing: 2) {
                Text("Scrum Flashcards")
                    .font(.title.weight(.black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                Text("Master the framework, one card at a time")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}

#Preview("Logo") {
    ZStack {
        LinearGradient(
            colors: [Color.indigo, Color.purple, Color.pink.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        ScrumWordmarkView()
    }
}
