import SwiftUI

struct WeatherBackground: View {
    let condition: WeatherConditionKind
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            RadialGradient(
                colors: [glow.opacity(colorScheme == .dark ? 0.55 : 0.78), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 350
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.07 : 0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 3)
                .offset(x: animate ? -170 : -120, y: animate ? 310 : 250)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.20))
                .frame(width: 170, height: 170)
                .blur(radius: 8)
                .offset(x: animate ? 160 : 115, y: animate ? -150 : -105)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)

            particles
        }
        .onAppear { animate = true }
    }

    @ViewBuilder
    private var particles: some View {
        if condition == .rain || condition == .thunderstorm {
            ForEach(0..<22, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(0.18 + Double(index % 3) * 0.09))
                    .frame(width: 2.5, height: CGFloat(18 + index % 4 * 5))
                    .rotationEffect(.degrees(12))
                    .offset(x: CGFloat((index * 67) % 430) - 215, y: animate ? 760 : -240)
                    .animation(.linear(duration: Double(3 + index % 4)).repeatForever(autoreverses: false).delay(Double(index) * 0.08), value: animate)
            }
        } else if condition == .snow {
            ForEach(0..<18, id: \.self) { index in
                Image(systemName: "snowflake")
                    .font(.system(size: CGFloat(8 + index % 4 * 4), weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.30 + Double(index % 3) * 0.10))
                    .offset(x: CGFloat((index * 79) % 420) - 210, y: animate ? 740 : -220)
                    .animation(.linear(duration: Double(6 + index % 5)).repeatForever(autoreverses: false).delay(Double(index) * 0.16), value: animate)
            }
        }
    }

    private var glow: Color {
        switch condition {
        case .clear: return .yellow
        case .partlyCloudy: return .cyan
        case .cloudy, .fog: return Color(red: 0.78, green: 0.86, blue: 0.95)
        case .rain: return Color(red: 0.15, green: 0.75, blue: 1)
        case .thunderstorm: return Color(red: 0.75, green: 0.35, blue: 1)
        case .snow: return .white
        case .wind: return .mint
        }
    }

    private var palette: [Color] {
        if colorScheme == .dark {
            switch condition {
            case .clear: return [Color(red: 0.03, green: 0.12, blue: 0.28), Color(red: 0.10, green: 0.36, blue: 0.62)]
            case .partlyCloudy: return [Color(red: 0.05, green: 0.17, blue: 0.34), Color(red: 0.22, green: 0.45, blue: 0.62)]
            case .cloudy, .fog: return [Color(red: 0.08, green: 0.12, blue: 0.20), Color(red: 0.28, green: 0.35, blue: 0.47)]
            case .rain: return [Color(red: 0.03, green: 0.11, blue: 0.24), Color(red: 0.08, green: 0.31, blue: 0.49)]
            case .thunderstorm: return [Color(red: 0.08, green: 0.03, blue: 0.18), Color(red: 0.30, green: 0.12, blue: 0.44)]
            case .snow: return [Color(red: 0.13, green: 0.28, blue: 0.43), Color(red: 0.43, green: 0.60, blue: 0.72)]
            case .wind: return [Color(red: 0.02, green: 0.23, blue: 0.28), Color(red: 0.14, green: 0.49, blue: 0.45)]
            }
        } else {
            switch condition {
            case .clear: return [Color(red: 0.42, green: 0.82, blue: 1.0), Color(red: 1.0, green: 0.80, blue: 0.38)]
            case .partlyCloudy: return [Color(red: 0.48, green: 0.84, blue: 1.0), Color(red: 0.77, green: 0.73, blue: 0.98)]
            case .cloudy, .fog: return [Color(red: 0.69, green: 0.80, blue: 0.91), Color(red: 0.48, green: 0.62, blue: 0.78)]
            case .rain: return [Color(red: 0.35, green: 0.72, blue: 0.93), Color(red: 0.35, green: 0.51, blue: 0.72)]
            case .thunderstorm: return [Color(red: 0.47, green: 0.43, blue: 0.78), Color(red: 0.28, green: 0.32, blue: 0.58)]
            case .snow: return [Color(red: 0.70, green: 0.89, blue: 1.0), Color(red: 0.59, green: 0.75, blue: 0.90)]
            case .wind: return [Color(red: 0.37, green: 0.88, blue: 0.77), Color(red: 0.40, green: 0.70, blue: 0.85)]
            }
        }
    }
}
