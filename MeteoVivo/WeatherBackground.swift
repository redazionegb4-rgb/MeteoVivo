import SwiftUI

struct WeatherBackground: View {
    let condition: WeatherConditionKind
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(condition == .clear ? 0.28 : 0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 8)
                .offset(x: animate ? 130 : 90, y: animate ? -250 : -220)

            ForEach(0..<18, id: \.self) { index in
                Image(systemName: particleSymbol)
                    .font(.system(size: CGFloat(12 + (index % 4) * 5), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.14 + Double(index % 4) * 0.07))
                    .offset(x: CGFloat((index * 53) % 360) - 180,
                            y: animate ? 520 : -180)
                    .animation(.linear(duration: Double(5 + index % 5)).repeatForever(autoreverses: false).delay(Double(index) * 0.15), value: animate)
            }
        }
        .onAppear { animate = true }
    }

    private var particleSymbol: String {
        switch condition {
        case .rain, .thunderstorm: return "drop.fill"
        case .snow: return "snowflake"
        case .cloudy, .partlyCloudy, .fog: return "cloud.fill"
        case .wind: return "wind"
        case .clear: return "sparkles"
        }
    }

    private var gradientColors: [Color] {
        switch condition {
        case .clear: return [Color(red: 0.18, green: 0.55, blue: 0.96), Color(red: 0.55, green: 0.82, blue: 1.0)]
        case .partlyCloudy: return [Color(red: 0.24, green: 0.45, blue: 0.72), Color(red: 0.58, green: 0.72, blue: 0.84)]
        case .cloudy, .fog: return [Color(red: 0.31, green: 0.37, blue: 0.46), Color(red: 0.59, green: 0.63, blue: 0.68)]
        case .rain: return [Color(red: 0.12, green: 0.24, blue: 0.40), Color(red: 0.27, green: 0.42, blue: 0.56)]
        case .thunderstorm: return [Color(red: 0.10, green: 0.09, blue: 0.20), Color(red: 0.28, green: 0.24, blue: 0.43)]
        case .snow: return [Color(red: 0.45, green: 0.66, blue: 0.80), Color(red: 0.84, green: 0.91, blue: 0.95)]
        case .wind: return [Color(red: 0.22, green: 0.49, blue: 0.57), Color(red: 0.52, green: 0.76, blue: 0.72)]
        }
    }
}
