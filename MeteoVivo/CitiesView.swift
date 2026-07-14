import SwiftUI
import CoreLocation

struct CitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WeatherStore

    @State private var query = ""
    @State private var results: [CLPlacemark] = []
    @State private var searching = false
    @State private var searchError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.74, blue: 0.98),
                        Color(red: 0.38, green: 0.45, blue: 0.95),
                        Color(red: 0.84, green: 0.28, blue: 0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        titleCard
                        searchBar

                        if searching {
                            ProgressView("Ricerca in corso…")
                                .tint(.white)
                                .foregroundStyle(.white)
                                .padding(.top, 6)
                        }

                        if let searchError {
                            Text(searchError)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.84))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if !results.isEmpty {
                            resultsSection
                        }

                        popularSection

                        if !store.favorites.isEmpty {
                            favoritesSection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Altre città")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fine") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onSubmit(of: .text) {
                search()
            }
        }
    }

    private var titleCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 66, height: 66)

                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Scegli un’altra città")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("La posizione attuale rimane nella home. Da qui puoi cercare e aprire altre località.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .padding(.top, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Cerca città o paese", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    searchError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Button("Cerca") {
                search()
            }
            .font(.subheadline.bold())
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(Color.white.opacity(0.50), lineWidth: 1)
        )
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Risultati", symbol: "magnifyingglass")

            VStack(spacing: 10) {
                ForEach(results, id: \.self) { placemark in
                    Button {
                        select(placemark)
                    } label: {
                        cityRow(
                            name: placemark.locality ?? placemark.name ?? "Località",
                            subtitle: [placemark.administrativeArea, placemark.country]
                                .compactMap { $0 }
                                .joined(separator: ", "),
                            symbol: "mappin.and.ellipse"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Città popolari", symbol: "sparkles")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                quickCity("Roma", "Italia", 41.9028, 12.4964, "building.columns.fill")
                quickCity("Milano", "Italia", 45.4642, 9.1900, "building.2.fill")
                quickCity("Napoli", "Italia", 40.8518, 14.2681, "water.waves")
                quickCity("Palermo", "Italia", 38.1157, 13.3615, "sun.max.fill")
                quickCity("Torino", "Italia", 45.0703, 7.6869, "mountain.2.fill")
                quickCity("Firenze", "Italia", 43.7696, 11.2558, "building.columns.fill")
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Preferite", symbol: "star.fill")

            VStack(spacing: 10) {
                ForEach(store.favorites) { city in
                    Button {
                        Task {
                            await store.loadWeather(
                                latitude: city.latitude,
                                longitude: city.longitude,
                                city: city.city,
                                country: city.country
                            )
                            dismiss()
                        }
                    } label: {
                        cityRow(
                            name: city.city,
                            subtitle: city.country,
                            symbol: "star.fill",
                            trailing: "\(Int(city.temperature.rounded()))°"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionTitle(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
    }

    private func quickCity(
        _ city: String,
        _ country: String,
        _ latitude: Double,
        _ longitude: Double,
        _ symbol: String
    ) -> some View {
        Button {
            Task {
                await store.loadWeather(
                    latitude: latitude,
                    longitude: longitude,
                    city: city,
                    country: country
                )
                dismiss()
            }
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: symbol)
                    .font(.title3.bold())
                    .symbolRenderingMode(.multicolor)

                Text(city)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Text(country)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(16)
            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(Color.white.opacity(0.26), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func cityRow(
        name: String,
        subtitle: String,
        symbol: String,
        trailing: String? = nil
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 48, height: 48)

                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        )
    }

    private func search() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        searching = true
        searchError = nil
        results = []

        CLGeocoder().geocodeAddressString(text) { placemarks, error in
            DispatchQueue.main.async {
                searching = false

                if let error {
                    searchError = "Nessuna città trovata: \(error.localizedDescription)"
                    return
                }

                results = placemarks ?? []

                if results.isEmpty {
                    searchError = "Nessun risultato trovato."
                }
            }
        }
    }

    private func select(_ placemark: CLPlacemark) {
        guard let location = placemark.location else { return }

        Task {
            await store.loadWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                city: placemark.locality ?? placemark.name ?? query,
                country: placemark.country ?? ""
            )
            dismiss()
        }
    }
}
