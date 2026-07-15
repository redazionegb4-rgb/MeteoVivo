import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WeatherStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.16, blue: 0.34),
                        Color(red: 0.24, green: 0.23, blue: 0.55),
                        Color(red: 0.55, green: 0.21, blue: 0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        appearanceCard
                        weatherCard
                        informationCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fine") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private var appearanceCard: some View {
        settingsCard(title: "Aspetto", symbol: "paintpalette.fill") {
            VStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        store.theme = theme
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(themeGradient(theme))
                                    .frame(width: 46, height: 46)

                                Image(systemName: themeSymbol(theme))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(theme.rawValue)
                                    .font(.headline.bold())
                                    .foregroundStyle(.primary)

                                Text(themeDescription(theme))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: store.theme == theme ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(store.theme == theme ? Color.blue : Color.secondary)
                        }
                        .padding(12)
                        .background(
                            store.theme == theme ? Color.blue.opacity(0.10) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var weatherCard: some View {
        settingsCard(title: "Dati meteorologici", symbol: "cloud.sun.fill") {
            VStack(spacing: 16) {
                AppleWeatherAttributionView()

                Divider()

                infoRow(
                    title: "Aggiornamento",
                    value: "Manuale e automatico",
                    symbol: "arrow.clockwise"
                )

                Text("Le condizioni e le previsioni visualizzate nell’app sono fornite da Apple Weather. Tocca il collegamento per consultare le fonti legali dei dati.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var informationCard: some View {
        settingsCard(title: "Informazioni", symbol: "info.circle.fill") {
            VStack(spacing: 14) {
                infoRow(
                    title: "Applicazione",
                    value: "Meteo Vivo",
                    symbol: "app.fill"
                )

                Divider()

                infoRow(
                    title: "Versione",
                    value: "1.0",
                    symbol: "number"
                )

                Divider()

                HStack(spacing: 13) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy")
                            .font(.subheadline.bold())
                        Text("Nessun account e nessun profilo personale.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    private func settingsCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(title, systemImage: symbol)
                .font(.headline.bold())
                .foregroundStyle(.primary)

            content()
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 20, y: 12)
    }

    private func infoRow(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

            Text(title)
                .font(.subheadline.bold())

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func themeSymbol(_ theme: AppTheme) -> String {
        switch theme {
        case .automatic: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    private func themeDescription(_ theme: AppTheme) -> String {
        switch theme {
        case .automatic: return "Segue l’aspetto dell’iPhone"
        case .light: return "Colori chiari e luminosi"
        case .dark: return "Colori scuri e rilassanti"
        }
    }

    private func themeGradient(_ theme: AppTheme) -> LinearGradient {
        switch theme {
        case .automatic:
            return LinearGradient(colors: [.white, .black], startPoint: .leading, endPoint: .trailing)
        case .light:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [.indigo, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}


struct AppleWeatherAttributionView: View {
    @EnvironmentObject private var store: WeatherStore
    @Environment(\.colorScheme) private var colorScheme

    var compact: Bool = false

    private var selectedMarkURL: URL? {
        colorScheme == .dark
            ? store.weatherMarkDarkURL
            : store.weatherMarkLightURL
    }

    var body: some View {
        VStack(spacing: compact ? 7 : 11) {
            attributionMark

            if let legalURL = store.weatherLegalURL {
                Link(destination: legalURL) {
                    HStack(spacing: 6) {
                        Text("Fonti legali dei dati meteo")
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.bold())
                    }
                    .font(
                        compact
                            ? .caption2.weight(.semibold)
                            : .caption.weight(.semibold)
                    )
                }
                .accessibilityLabel("Fonti legali dei dati meteo Apple Weather")
            } else {
                Text("Fonti legali dei dati meteo")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            if store.weatherLegalURL == nil {
                await store.loadWeatherAttribution()
            }
        }
    }

    @ViewBuilder
    private var attributionMark: some View {
        if let selectedMarkURL {
            AsyncImage(url: selectedMarkURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    fallbackMark
                @unknown default:
                    fallbackMark
                }
            }
            .frame(height: compact ? 22 : 30)
        } else {
            fallbackMark
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
            .accessibilityLabel("Apple Weather")
    }
}
