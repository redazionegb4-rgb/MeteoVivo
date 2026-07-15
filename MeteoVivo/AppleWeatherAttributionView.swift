import SwiftUI

struct AppleWeatherAttributionView: View {
    @EnvironmentObject private var store: WeatherStore
    @Environment(\.colorScheme) private var colorScheme

    var compact = false

    private var markURL: URL? {
        colorScheme == .dark
            ? store.appleWeatherMarkDarkURL
            : store.appleWeatherMarkLightURL
    }

    var body: some View {
        VStack(spacing: compact ? 7 : 11) {
            Group {
                if let markURL {
                    AsyncImage(url: markURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .empty:
                            ProgressView()
                        case .failure:
                            fallbackMark
                        @unknown default:
                            fallbackMark
                        }
                    }
                } else {
                    fallbackMark
                }
            }
            .frame(height: compact ? 23 : 30)
            .accessibilityLabel("Apple Weather")

            if let legalURL = store.appleWeatherLegalURL {
                Link(destination: legalURL) {
                    HStack(spacing: 6) {
                        Text("Fonti dei dati meteorologici")
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.bold())
                    }
                    .font(
                        compact
                            ? .caption2.weight(.semibold)
                            : .caption.weight(.semibold)
                    )
                }
            } else {
                Text("Fonti dei dati meteorologici")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            if store.appleWeatherLegalURL == nil {
                await store.loadWeatherAttribution()
            }
        }
    }

    private var fallbackMark: some View {
        Text(" Weather")
            .font(
                .system(
                    size: compact ? 16 : 20,
                    weight: .semibold
                )
            )
            .foregroundStyle(.primary)
    }
}
