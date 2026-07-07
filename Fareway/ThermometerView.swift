import SwiftUI

/// The signature visual: a classic fundraiser-poster thermometer that fills
/// with a sunset-gradient mercury column. The fill height animates with a
/// spring whenever `progress` changes (i.e. on every new deposit), and a
/// confetti burst plays once the fund crosses 100%.
struct ThermometerView: View {
    let progress: Double   // 0...1, clamped by caller
    let overfunded: Bool
    var height: CGFloat = 160
    var width: CGFloat = 40

    @State private var animatedProgress: Double = 0

    private let bulbDiameter: CGFloat

    init(progress: Double, overfunded: Bool, height: CGFloat = 160, width: CGFloat = 40) {
        self.progress = progress
        self.overfunded = overfunded
        self.height = height
        self.width = width
        self.bulbDiameter = width * 1.8
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Glass tube outline.
                Capsule()
                    .stroke(FWTheme.ink.opacity(0.25), lineWidth: 2)
                    .frame(width: width, height: height)

                // Tick marks (classic fundraiser-poster look).
                VStack(spacing: (height - 16) / 5) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(FWTheme.ink.opacity(0.18))
                            .frame(width: width * 0.4, height: 1.5)
                    }
                }
                .frame(height: height - 16)
                .padding(.bottom, 8)

                // Mercury fill.
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [FWTheme.mercuryBottom, FWTheme.mercuryMid, FWTheme.mercuryTop],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: width - 8, height: max(6, (height - 8) * animatedProgress))
                    .padding(.bottom, 4)
                    .clipShape(Capsule())
            }
            .frame(width: bulbDiameter, height: height, alignment: .bottom)

            // Bulb at the base.
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FWTheme.mercuryMid, FWTheme.mercuryTop],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: bulbDiameter, height: bulbDiameter)
                Circle()
                    .stroke(FWTheme.ink.opacity(0.25), lineWidth: 2)
                    .frame(width: bulbDiameter, height: bulbDiameter)
            }
            .offset(y: -bulbDiameter * 0.32)
        }
        .accessibilityIdentifier("thermometerVisual")
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

/// Pure-SwiftUI confetti burst, no external assets or libraries. Spawns a
/// handful of small colored rectangles that fall and rotate, then removes
/// itself. Triggered once whenever a fund crosses 100% of its target.
struct ConfettiBurstView: View {
    struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let xOffset: CGFloat
        let delay: Double
        let rotation: Double
        let size: CGFloat
    }

    @State private var animate = false
    private let pieces: [Piece]

    init(pieceCount: Int = 24) {
        let colors = [FWTheme.mercuryTop, FWTheme.mercuryMid, FWTheme.mercuryBottom, FWTheme.teal, FWTheme.brass]
        self.pieces = (0..<pieceCount).map { i in
            Piece(
                color: colors[i % colors.count],
                xOffset: CGFloat.random(in: -120...120),
                delay: Double.random(in: 0...0.25),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...11)
            )
        }
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.5)
                    .rotationEffect(.degrees(animate ? piece.rotation + 180 : piece.rotation))
                    .offset(x: piece.xOffset, y: animate ? 220 : -20)
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeIn(duration: 1.1).delay(piece.delay),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("goalCelebrationConfetti")
        .onAppear {
            animate = true
        }
    }
}
