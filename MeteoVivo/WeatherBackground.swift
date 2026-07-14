import SwiftUI

struct WeatherBackground: View {
    let condition: WeatherConditionKind

    @Environment(\.colorScheme) private var colorScheme
    @State private var animatePrimary = false
    @State private var animateSecondary = false
    @State private var flash = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: palette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ambientGlows
            animatedScene
        }
        .onAppear {
            animatePrimary = true
            animateSecondary = true

            if condition == .thunderstorm {
                startLightningLoop()
            }
        }
        .onChange(of: condition) { newValue in
            flash = false
            if newValue == .thunderstorm {
                startLightningLoop()
            }
        }
    }

    private var ambientGlows: some View {
        ZStack {
            Circle()
                .fill(glow.opacity(colorScheme == .dark ? 0.34 : 0.58))
                .frame(width: 360, height: 360)
                .blur(radius: 46)
                .offset(
                    x: animateSecondary ? 150 : 95,
                    y: animateSecondary ? -315 : -255
                )
                .animation(
                    .easeInOut(duration: 6.5)
                        .repeatForever(autoreverses: true),
                    value: animateSecondary
                )

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.18))
                .frame(width: 270, height: 270)
                .blur(radius: 34)
                .offset(
                    x: animateSecondary ? -165 : -105,
                    y: animateSecondary ? 345 : 280
                )
                .animation(
                    .easeInOut(duration: 7.5)
                        .repeatForever(autoreverses: true),
                    value: animateSecondary
                )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var animatedScene: some View {
        switch condition {
        case .clear:
            sunScene
        case .partlyCloudy:
            cloudScene(showSun: true)
        case .cloudy:
            cloudScene(showSun: false)
        case .rain:
            rainScene
        case .thunderstorm:
            thunderScene
        case .snow:
            snowScene
        case .hail:
            hailScene
        case .sleet:
            sleetScene
        case .fog:
            fogScene
        case .wind:
            windScene
        }
    }

    private var sunScene: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.98),
                            Color.orange.opacity(0.78),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 120
                    )
                )
                .frame(width: 230, height: 230)
                .offset(x: 125, y: -275)
                .scaleEffect(animatePrimary ? 1.08 : 0.93)
                .animation(
                    .easeInOut(duration: 3.2)
                        .repeatForever(autoreverses: true),
                    value: animatePrimary
                )

            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color.yellow.opacity(0.55))
                    .frame(width: 8, height: 72)
                    .offset(y: -154)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
            .rotationEffect(.degrees(animatePrimary ? 360 : 0))
            .offset(x: 125, y: -275)
            .animation(
                .linear(duration: 28)
                    .repeatForever(autoreverses: false),
                value: animatePrimary
            )

            sparkleField
        }
    }

    private func cloudScene(showSun: Bool) -> some View {
        ZStack {
            if showSun {
                Circle()
                    .fill(Color.yellow.opacity(0.90))
                    .frame(width: 120, height: 120)
                    .blur(radius: 2)
                    .offset(x: 145, y: -285)
                    .scaleEffect(animateSecondary ? 1.06 : 0.94)
                    .animation(
                        .easeInOut(duration: 3.5)
                            .repeatForever(autoreverses: true),
                        value: animateSecondary
                    )
            }

            cloudLayer(
                scale: 1.15,
                opacity: colorScheme == .dark ? 0.17 : 0.32,
                y: -250,
                duration: 19,
                reverse: false
            )

            cloudLayer(
                scale: 0.78,
                opacity: colorScheme == .dark ? 0.10 : 0.20,
                y: -115,
                duration: 25,
                reverse: true
            )
        }
    }

    private var rainScene: some View {
        ZStack {
            cloudScene(showSun: false)

            ForEach(0..<42, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(0.24 + Double(index % 4) * 0.07))
                    .frame(
                        width: 2.4,
                        height: CGFloat(18 + (index % 5) * 6)
                    )
                    .rotationEffect(.degrees(12))
                    .offset(
                        x: CGFloat((index * 73) % 460) - 230,
                        y: animatePrimary ? 780 : -260
                    )
                    .animation(
                        .linear(duration: Double(2.4 + (index % 5)) * 0.42)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index % 14) * 0.10),
                        value: animatePrimary
                    )
            }
        }
    }

    private var thunderScene: some View {
        ZStack {
            rainScene

            Color.white
                .opacity(flash ? 0.34 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.12), value: flash)

            Image(systemName: "bolt.fill")
                .font(.system(size: 145, weight: .black))
                .foregroundStyle(Color.yellow.opacity(flash ? 0.95 : 0.05))
                .shadow(
                    color: Color.yellow.opacity(flash ? 0.95 : 0),
                    radius: 28
                )
                .offset(x: 110, y: -125)
                .animation(.easeOut(duration: 0.10), value: flash)
        }
    }

    private var snowScene: some View {
        ZStack {
            cloudScene(showSun: false)

            ForEach(0..<34, id: \.self) { index in
                Image(systemName: "snowflake")
                    .font(
                        .system(
                            size: CGFloat(8 + (index % 5) * 4),
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.34 + Double(index % 4) * 0.11)
                    )
                    .rotationEffect(.degrees(animateSecondary ? 220 : 0))
                    .offset(
                        x: animateSecondary
                            ? CGFloat((index * 79) % 470) - 235 + CGFloat((index % 3) * 18)
                            : CGFloat((index * 79) % 470) - 235,
                        y: animatePrimary ? 790 : -250
                    )
                    .animation(
                        .linear(duration: Double(6 + index % 6))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index % 12) * 0.18),
                        value: animatePrimary
                    )
            }
        }
    }

    private var hailScene: some View {
        ZStack {
            cloudScene(showSun: false)

            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.cyan.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: CGFloat(7 + index % 4 * 3),
                        height: CGFloat(7 + index % 4 * 3)
                    )
                    .shadow(color: Color.white.opacity(0.40), radius: 4)
                    .offset(
                        x: CGFloat((index * 83) % 460) - 230,
                        y: animatePrimary ? 800 : -260
                    )
                    .animation(
                        .linear(duration: Double(2.0 + index % 4) * 0.42)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index % 10) * 0.13),
                        value: animatePrimary
                    )
            }
        }
    }

    private var sleetScene: some View {
        ZStack {
            rainScene

            ForEach(0..<18, id: \.self) { index in
                Image(systemName: "snowflake")
                    .font(.system(size: CGFloat(8 + index % 4 * 3)))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .offset(
                        x: CGFloat((index * 97) % 450) - 225,
                        y: animateSecondary ? 780 : -250
                    )
                    .animation(
                        .linear(duration: Double(5 + index % 4))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index % 8) * 0.20),
                        value: animateSecondary
                    )
            }
        }
    }

    private var fogScene: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.02),
                                Color.white.opacity(
                                    colorScheme == .dark ? 0.15 : 0.32
                                ),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: CGFloat(300 + index * 38),
                        height: CGFloat(28 + index % 3 * 10)
                    )
                    .blur(radius: 8)
                    .offset(
                        x: animatePrimary
                            ? CGFloat(135 - index * 15)
                            : CGFloat(-175 + index * 10),
                        y: CGFloat(-250 + index * 105)
                    )
                    .animation(
                        .easeInOut(duration: Double(6 + index))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.18),
                        value: animatePrimary
                    )
            }
        }
    }

    private var windScene: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                HStack(spacing: 8) {
                    Capsule()
                        .frame(width: CGFloat(95 + index % 4 * 35), height: 4)
                    Circle()
                        .frame(width: 8, height: 8)
                }
                .foregroundStyle(
                    Color.white.opacity(0.16 + Double(index % 4) * 0.08)
                )
                .offset(
                    x: animatePrimary ? 330 : -340,
                    y: CGFloat(-320 + index * 65)
                )
                .animation(
                    .linear(duration: Double(2.8 + index % 5) * 0.65)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.12),
                    value: animatePrimary
                )
            }

            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "leaf.fill")
                    .font(.system(size: CGFloat(11 + index % 3 * 4)))
                    .foregroundStyle(Color.mint.opacity(0.35))
                    .rotationEffect(.degrees(animateSecondary ? 540 : 0))
                    .offset(
                        x: animateSecondary ? 290 : -310,
                        y: CGFloat(-260 + index * 95)
                    )
                    .animation(
                        .linear(duration: Double(4 + index % 4))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.18),
                        value: animateSecondary
                    )
            }
        }
    }

    private var sparkleField: some View {
        ForEach(0..<14, id: \.self) { index in
            Circle()
                .fill(Color.white.opacity(0.20 + Double(index % 3) * 0.10))
                .frame(
                    width: CGFloat(3 + index % 4 * 2),
                    height: CGFloat(3 + index % 4 * 2)
                )
                .scaleEffect(animateSecondary ? 1.4 : 0.55)
                .opacity(animateSecondary ? 0.85 : 0.20)
                .offset(
                    x: CGFloat((index * 97) % 420) - 210,
                    y: CGFloat((index * 131) % 720) - 360
                )
                .animation(
                    .easeInOut(duration: Double(1.8 + index % 4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.11),
                    value: animateSecondary
                )
        }
    }

    private func cloudLayer(
        scale: CGFloat,
        opacity: Double,
        y: CGFloat,
        duration: Double,
        reverse: Bool
    ) -> some View {
        ZStack {
            Circle()
                .frame(width: 145, height: 145)
                .offset(x: -85, y: 8)
            Circle()
                .frame(width: 190, height: 190)
                .offset(x: 8, y: -28)
            Circle()
                .frame(width: 130, height: 130)
                .offset(x: 105, y: 15)
            Capsule()
                .frame(width: 330, height: 105)
                .offset(y: 55)
        }
        .foregroundStyle(Color.white.opacity(opacity))
        .scaleEffect(scale)
        .blur(radius: 2)
        .offset(
            x: animatePrimary
                ? (reverse ? -230 : 230)
                : (reverse ? 230 : -230),
            y: y
        )
        .animation(
            .linear(duration: duration)
                .repeatForever(autoreverses: true),
            value: animatePrimary
        )
    }

    private var glow: Color {
        switch condition {
        case .clear:
            return .yellow
        case .partlyCloudy:
            return .cyan
        case .cloudy, .fog:
            return Color(red: 0.78, green: 0.86, blue: 0.95)
        case .rain:
            return Color(red: 0.15, green: 0.75, blue: 1)
        case .thunderstorm:
            return Color(red: 0.75, green: 0.35, blue: 1)
        case .snow, .sleet:
            return .white
        case .hail:
            return .cyan
        case .wind:
            return .mint
        }
    }

    private var palette: [Color] {
        if colorScheme == .dark {
            switch condition {
            case .clear:
                return [
                    Color(red: 0.03, green: 0.12, blue: 0.28),
                    Color(red: 0.10, green: 0.36, blue: 0.62)
                ]
            case .partlyCloudy:
                return [
                    Color(red: 0.05, green: 0.17, blue: 0.34),
                    Color(red: 0.22, green: 0.45, blue: 0.62)
                ]
            case .cloudy, .fog:
                return [
                    Color(red: 0.08, green: 0.12, blue: 0.20),
                    Color(red: 0.28, green: 0.35, blue: 0.47)
                ]
            case .rain:
                return [
                    Color(red: 0.03, green: 0.11, blue: 0.24),
                    Color(red: 0.08, green: 0.31, blue: 0.49)
                ]
            case .thunderstorm:
                return [
                    Color(red: 0.08, green: 0.03, blue: 0.18),
                    Color(red: 0.30, green: 0.12, blue: 0.44)
                ]
            case .snow, .sleet:
                return [
                    Color(red: 0.13, green: 0.28, blue: 0.43),
                    Color(red: 0.43, green: 0.60, blue: 0.72)
                ]
            case .hail:
                return [
                    Color(red: 0.08, green: 0.26, blue: 0.42),
                    Color(red: 0.30, green: 0.62, blue: 0.78)
                ]
            case .wind:
                return [
                    Color(red: 0.02, green: 0.23, blue: 0.28),
                    Color(red: 0.14, green: 0.49, blue: 0.45)
                ]
            }
        } else {
            switch condition {
            case .clear:
                return [
                    Color(red: 0.42, green: 0.82, blue: 1.0),
                    Color(red: 1.0, green: 0.80, blue: 0.38)
                ]
            case .partlyCloudy:
                return [
                    Color(red: 0.48, green: 0.84, blue: 1.0),
                    Color(red: 0.77, green: 0.73, blue: 0.98)
                ]
            case .cloudy, .fog:
                return [
                    Color(red: 0.69, green: 0.80, blue: 0.91),
                    Color(red: 0.48, green: 0.62, blue: 0.78)
                ]
            case .rain:
                return [
                    Color(red: 0.35, green: 0.72, blue: 0.93),
                    Color(red: 0.35, green: 0.51, blue: 0.72)
                ]
            case .thunderstorm:
                return [
                    Color(red: 0.47, green: 0.43, blue: 0.78),
                    Color(red: 0.28, green: 0.32, blue: 0.58)
                ]
            case .snow, .sleet:
                return [
                    Color(red: 0.70, green: 0.89, blue: 1.0),
                    Color(red: 0.59, green: 0.75, blue: 0.90)
                ]
            case .hail:
                return [
                    Color(red: 0.58, green: 0.83, blue: 0.95),
                    Color(red: 0.39, green: 0.66, blue: 0.82)
                ]
            case .wind:
                return [
                    Color(red: 0.37, green: 0.88, blue: 0.77),
                    Color(red: 0.40, green: 0.70, blue: 0.85)
                ]
            }
        }
    }

    private func startLightningLoop() {
        guard condition == .thunderstorm else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            guard condition == .thunderstorm else { return }

            flash = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                flash = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    guard condition == .thunderstorm else { return }
                    flash = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                        flash = false
                        startLightningLoop()
                    }
                }
            }
        }
    }
}
