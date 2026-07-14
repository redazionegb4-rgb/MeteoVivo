import SwiftUI

struct WeatherBackground: View {
    let condition: WeatherConditionKind
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(accentGlow.opacity(colorScheme == .dark ? 0.26 : 0.42))
                .frame(width: 330, height: 330)
                .blur(radius: 32)
                .offset(x: animate ? 145 : 95, y: animate ? -300 : -250)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.20))
                .frame(width: 240, height: 240)
                .blur(radius: 38)
                .offset(x: animate ? -145 : -105, y: animate ? 330 : 280)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)

            if condition == .rain || condition == .thunderstorm || condition == .snow {
                particles
            }
        }
        .onAppear { animate = true }
    }

    private var particles: some View {
        ForEach(0..<18, id: \.self) { index in
            Image(systemName: condition == .snow ? "snowflake" : "drop.fill")
                .font(.system(size: CGFloat(10 + index % 4 * 4), weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.18 + Double(index % 3) * 0.08))
                .offset(
                    x: CGFloat((index * 61) % 390) - 195,
                    y: animate ? 650 : -200
                )
                .animation(
                    .linear(duration: Double(5 + index % 5))
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.12),
                    value: animate
                )
        }
    }

    private var accentGlow: Color {
        switch condition {
        case .clear: return Color(red: 1.0, green: 0.72, blue: 0.22)
        case .partlyCloudy: return Color(red: 0.35, green: 0.80, blue: 0.95)
        case .cloudy, .fog: return Color(red: 0.67, green: 0.78, blue: 0.86)
        case .rain: return Color(red: 0.25, green: 0.72, blue: 0.95)
        case .thunderstorm: return Color(red: 0.65, green: 0.42, blue: 0.98)
        case .snow: return Color(red: 0.78, green: 0.93, blue: 1.0)
        case .wind: return Color(red: 0.26, green: 0.86, blue: 0.72)
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            switch condition {
            case .clear: return [Color(red: 0.05, green: 0.13, blue: 0.29), Color(red: 0.09, green: 0.31, blue: 0.55)]
            case .partlyCloudy: return [Color(red: 0.08, green: 0.16, blue: 0.31), Color(red: 0.18, green: 0.35, blue: 0.52)]
            case .cloudy, .fog: return [Color(red: 0.11, green: 0.15, blue: 0.23), Color(red: 0.28, green: 0.34, blue: 0.44)]
            case .rain: return [Color(red: 0.04, green: 0.12, blue: 0.24), Color(red: 0.10, green: 0.27, blue: 0.42)]
            case .thunderstorm: return [Color(red: 0.08, green: 0.05, blue: 0.18), Color(red: 0.24, green: 0.14, blue: 0.38)]
            case .snow: return [Color(red: 0.16, green: 0.28, blue: 0.42), Color(red: 0.38, green: 0.52, blue: 0.65)]
            case .wind: return [Color(red: 0.04, green: 0.23, blue: 0.27), Color(red: 0.12, green: 0.42, blue: 0.43)]
            }
        } else {
            switch condition {
            case .clear: return [Color(red: 0.72, green: 0.91, blue: 1.0), Color(red: 0.96, green: 0.87, blue: 0.64)]
            case .partlyCloudy: return [Color(red: 0.75, green: 0.91, blue: 1.0), Color(red: 0.83, green: 0.87, blue: 0.94)]
            case .cloudy, .fog: return [Color(red: 0.83, green: 0.88, blue: 0.93), Color(red: 0.70, green: 0.78, blue: 0.86)]
            case .rain: return [Color(red: 0.65, green: 0.82, blue: 0.93), Color(red: 0.54, green: 0.70, blue: 0.82)]
            case .thunderstorm: return [Color(red: 0.63, green: 0.62, blue: 0.80), Color(red: 0.43, green: 0.48, blue: 0.66)]
            case .snow: return [Color(red: 0.86, green: 0.95, blue: 1.0), Color(red: 0.72, green: 0.85, blue: 0.94)]
            case .wind: return [Color(red: 0.68, green: 0.92, blue: 0.88), Color(red: 0.62, green: 0.82, blue: 0.88)]
            }
        }
    }
}
