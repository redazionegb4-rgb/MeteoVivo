import SwiftUI

struct WeatherBackground: View {
    let condition: WeatherConditionKind
    let isDaytime: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false
    @State private var flash = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: sceneColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            glowLayer
            effectLayer
        }
        .onAppear {
            animate = true
            if condition == .thunderstorm {
                triggerLightning()
            }
        }
        .onChange(of: condition) { value in
            if value == .thunderstorm {
                triggerLightning()
            } else {
                flash = false
            }
        }
    }

    private var glowLayer: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(colorScheme == .dark ? 0.26 : 0.46))
                .frame(width: 320, height: 320)
                .blur(radius: 42)
                .offset(x: animate ? 145 : 95, y: animate ? -300 : -245)
                .animation(
                    .easeInOut(duration: 6)
                        .repeatForever(autoreverses: true),
                    value: animate
                )

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .offset(x: animate ? -150 : -100, y: animate ? 330 : 270)
                .animation(
                    .easeInOut(duration: 7)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
        }
    }

    @ViewBuilder
    private var effectLayer: some View {
        switch condition {
        case .clear:
            if isDaytime {
                SunAnimation(animate: animate)
            } else {
                NightSkyAnimation(animate: animate, cloudy: false)
            }
        case .partlyCloudy:
            if isDaytime {
                CloudAnimation(animate: animate, showSun: true)
            } else {
                ZStack {
                    NightSkyAnimation(animate: animate, cloudy: true)
                    CloudAnimation(animate: animate, showSun: false)
                }
            }
        case .cloudy:
            CloudAnimation(animate: animate, showSun: false)
        case .rain:
            RainAnimation(animate: animate)
        case .thunderstorm:
            ThunderAnimation(animate: animate, flash: flash)
        case .snow:
            SnowAnimation(animate: animate)
        case .hail:
            HailAnimation(animate: animate)
        case .sleet:
            SleetAnimation(animate: animate)
        case .fog:
            FogAnimation(animate: animate)
        case .wind:
            WindAnimation(animate: animate)
        }
    }

    private var sceneColors: [Color] {
        if !isDaytime {
            switch condition {
            case .rain, .thunderstorm:
                return [
                    Color(red: 0.015, green: 0.04, blue: 0.10),
                    Color(red: 0.08, green: 0.14, blue: 0.24)
                ]
            case .snow, .sleet, .hail:
                return [
                    Color(red: 0.03, green: 0.08, blue: 0.16),
                    Color(red: 0.15, green: 0.25, blue: 0.38)
                ]
            default:
                return [
                    Color(red: 0.015, green: 0.025, blue: 0.10),
                    Color(red: 0.08, green: 0.10, blue: 0.28)
                ]
            }
        }

        return backgroundColors
    }

    private var accentColor: Color {
        switch condition {
        case .clear: return .yellow
        case .partlyCloudy: return .cyan
        case .cloudy, .fog: return Color(red: 0.75, green: 0.84, blue: 0.93)
        case .rain: return Color(red: 0.18, green: 0.72, blue: 1.0)
        case .thunderstorm: return Color(red: 0.70, green: 0.35, blue: 1.0)
        case .snow, .sleet: return .white
        case .hail: return .cyan
        case .wind: return .mint
        }
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return darkColors
        }
        return lightColors
    }

    private var darkColors: [Color] {
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
    }

    private var lightColors: [Color] {
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

    private func triggerLightning() {
        guard condition == .thunderstorm else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard condition == .thunderstorm else { return }
            flash = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                flash = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    guard condition == .thunderstorm else { return }
                    flash = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        flash = false
                        triggerLightning()
                    }
                }
            }
        }
    }
}

private struct SunAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.90))
                .frame(width: 150, height: 150)
                .shadow(color: Color.orange.opacity(0.55), radius: 36)
                .scaleEffect(animate ? 1.08 : 0.94)
                .animation(
                    .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                    value: animate
                )

            Image(systemName: "sun.max.fill")
                .font(.system(size: 170))
                .foregroundStyle(Color.yellow.opacity(0.34))
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(
                    .linear(duration: 24)
                        .repeatForever(autoreverses: false),
                    value: animate
                )
        }
        .offset(x: 120, y: -260)
    }
}

private struct CloudAnimation: View {
    let animate: Bool
    let showSun: Bool

    var body: some View {
        ZStack {
            if showSun {
                Circle()
                    .fill(Color.yellow.opacity(0.78))
                    .frame(width: 105, height: 105)
                    .offset(x: 140, y: -285)
            }

            cloud(opacity: 0.22, scale: 1.05)
                .offset(x: animate ? 215 : -215, y: -220)
                .animation(
                    .linear(duration: 18)
                        .repeatForever(autoreverses: true),
                    value: animate
                )

            cloud(opacity: 0.12, scale: 0.72)
                .offset(x: animate ? -225 : 225, y: -85)
                .animation(
                    .linear(duration: 24)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
        }
    }

    private func cloud(opacity: Double, scale: CGFloat) -> some View {
        ZStack {
            Circle().frame(width: 120, height: 120).offset(x: -70)
            Circle().frame(width: 160, height: 160).offset(y: -25)
            Circle().frame(width: 110, height: 110).offset(x: 80)
            Capsule().frame(width: 275, height: 90).offset(y: 45)
        }
        .foregroundStyle(Color.white.opacity(opacity))
        .scaleEffect(scale)
    }
}


private struct NightSkyAnimation: View {
    let animate: Bool
    let cloudy: Bool

    var body: some View {
        ZStack {
            ForEach(0..<32, id: \.self) { index in
                NightStar(index: index, animate: animate)
            }

            MoonGlow(animate: animate)

            if cloudy {
                Color.indigo
                    .opacity(0.08)
                    .ignoresSafeArea()
            }
        }
    }
}

private struct NightStar: View {
    let index: Int
    let animate: Bool

    private var xPosition: CGFloat {
        CGFloat((index * 83) % 430) - 215
    }

    private var yPosition: CGFloat {
        CGFloat((index * 137) % 760) - 380
    }

    private var starSize: CGFloat {
        CGFloat(2 + (index % 4))
    }

    private var starOpacity: Double {
        0.28 + (Double(index % 4) * 0.16)
    }

    private var animationDuration: Double {
        1.7 + Double(index % 5)
    }

    private var animationDelay: Double {
        Double(index % 12) * 0.11
    }

    var body: some View {
        Circle()
            .fill(Color.white.opacity(starOpacity))
            .frame(width: starSize, height: starSize)
            .scaleEffect(animate ? 1.35 : 0.70)
            .opacity(animate ? 0.92 : 0.30)
            .offset(x: xPosition, y: yPosition)
            .animation(starAnimation, value: animate)
    }

    private var starAnimation: Animation {
        Animation
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
            .delay(animationDelay)
    }
}

private struct MoonGlow: View {
    let animate: Bool

    var body: some View {
        Circle()
            .fill(moonGradient)
            .frame(width: 150, height: 150)
            .offset(x: 135, y: -270)
            .scaleEffect(animate ? 1.04 : 0.96)
            .animation(moonAnimation, value: animate)
    }

    private var moonGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color.white.opacity(0.98),
                Color(red: 0.82, green: 0.88, blue: 1.0).opacity(0.75),
                Color.clear
            ],
            center: .center,
            startRadius: 5,
            endRadius: 85
        )
    }

    private var moonAnimation: Animation {
        Animation
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
    }
}

private struct RainAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            CloudAnimation(animate: animate, showSun: false)

            ForEach(0..<26, id: \.self) { index in
                RainDrop(index: index, animate: animate)
            }
        }
    }
}

private struct RainDrop: View {
    let index: Int
    let animate: Bool

    var body: some View {
        let x = CGFloat((index * 71) % 430) - 215
        let height = CGFloat(18 + (index % 4) * 6)
        let duration = Double(1.2 + Double(index % 4) * 0.22)
        let delay = Double(index % 10) * 0.10

        Capsule()
            .fill(Color.white.opacity(0.54))
            .frame(width: 2.5, height: height)
            .rotationEffect(.degrees(12))
            .offset(x: x, y: animate ? 760 : -240)
            .animation(
                .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: animate
            )
    }
}

private struct ThunderAnimation: View {
    let animate: Bool
    let flash: Bool

    var body: some View {
        ZStack {
            RainAnimation(animate: animate)

            Color.white
                .opacity(flash ? 0.30 : 0)
                .ignoresSafeArea()

            Image(systemName: "bolt.fill")
                .font(.system(size: 130, weight: .black))
                .foregroundStyle(Color.yellow.opacity(flash ? 0.95 : 0.05))
                .shadow(color: Color.yellow.opacity(flash ? 0.9 : 0), radius: 24)
                .offset(x: 100, y: -120)
        }
    }
}

private struct SnowAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            CloudAnimation(animate: animate, showSun: false)

            ForEach(0..<24, id: \.self) { index in
                SnowFlake(index: index, animate: animate)
            }
        }
    }
}

private struct SnowFlake: View {
    let index: Int
    let animate: Bool

    var body: some View {
        let x = CGFloat((index * 83) % 440) - 220
        let size = CGFloat(8 + (index % 4) * 4)
        let duration = Double(5 + index % 5)
        let delay = Double(index % 10) * 0.16

        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundStyle(Color.white.opacity(0.82))
            .rotationEffect(.degrees(animate ? 240 : 0))
            .offset(x: x, y: animate ? 760 : -240)
            .animation(
                .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: animate
            )
    }
}

private struct HailAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            CloudAnimation(animate: animate, showSun: false)

            ForEach(0..<22, id: \.self) { index in
                HailStone(index: index, animate: animate)
            }
        }
    }
}

private struct HailStone: View {
    let index: Int
    let animate: Bool

    var body: some View {
        let x = CGFloat((index * 79) % 430) - 215
        let size = CGFloat(7 + (index % 3) * 3)
        let duration = Double(1.1 + Double(index % 3) * 0.18)
        let delay = Double(index % 9) * 0.12

        Circle()
            .fill(Color.white.opacity(0.96))
            .frame(width: size, height: size)
            .shadow(color: Color.cyan.opacity(0.45), radius: 3)
            .offset(x: x, y: animate ? 770 : -240)
            .animation(
                .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: animate
            )
    }
}

private struct SleetAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            RainAnimation(animate: animate)

            ForEach(0..<12, id: \.self) { index in
                SnowFlake(index: index, animate: animate)
            }
        }
    }
}

private struct FogAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                FogBand(index: index, animate: animate)
            }
        }
    }
}

private struct FogBand: View {
    let index: Int
    let animate: Bool

    var body: some View {
        let width = CGFloat(290 + index * 35)
        let height = CGFloat(28 + (index % 2) * 10)
        let y = CGFloat(-260 + index * 100)
        let startX = CGFloat(-170 + index * 8)
        let endX = CGFloat(135 - index * 10)

        Capsule()
            .fill(Color.white.opacity(0.34))
            .frame(width: width, height: height)
            .blur(radius: 8)
            .offset(x: animate ? endX : startX, y: y)
            .animation(
                .easeInOut(duration: Double(6 + index))
                    .repeatForever(autoreverses: true),
                value: animate
            )
    }
}

private struct WindAnimation: View {
    let animate: Bool

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                WindLine(index: index, animate: animate)
            }
        }
    }
}

private struct WindLine: View {
    let index: Int
    let animate: Bool

    var body: some View {
        let width = CGFloat(90 + (index % 4) * 28)
        let y = CGFloat(-300 + index * 68)
        let duration = Double(2.4 + Double(index % 4) * 0.45)
        let delay = Double(index) * 0.12

        Capsule()
            .fill(Color.white.opacity(0.40))
            .frame(width: width, height: 4)
            .offset(x: animate ? 330 : -330, y: y)
            .animation(
                .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: animate
            )
    }
}
