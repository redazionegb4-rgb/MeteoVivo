import SwiftUI
import MapKit
import CoreLocation

struct CityCandidate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let country: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
}

@MainActor
final class CityLiveSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
    }

    func update(_ query: String) {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = []
            isSearching = false
            completer.queryFragment = ""
            return
        }
        isSearching = true
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = Array(completer.results.prefix(12))
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
        isSearching = false
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> CityCandidate? {
        let request = MKLocalSearch.Request(completion: completion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else { return nil }
            let placemark = item.placemark
            let coordinate = placemark.coordinate
            let name = placemark.locality ?? placemark.name ?? completion.title
            let country = placemark.country ?? ""
            let subtitle = [placemark.administrativeArea, placemark.country]
                .compactMap { $0 }
                .joined(separator: ", ")
            let timeZone = placemark.timeZone?.identifier ?? ""

            return CityCandidate(
                name: name,
                country: country,
                subtitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZoneIdentifier: timeZone
            )
        } catch {
            return nil
        }
    }
}

struct CitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WeatherStore
    @StateObject private var liveSearch = CityLiveSearch()
    @State private var query = ""
    @State private var selectedCandidate: CityCandidate?
    @State private var resolving = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.55, blue: 0.96),
                        Color(red: 0.32, green: 0.32, blue: 0.82),
                        Color(red: 0.68, green: 0.18, blue: 0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        introCard
                        searchField

                        if resolving || liveSearch.isSearching {
                            ProgressView("Ricerca città…")
                                .tint(.white)
                                .foregroundStyle(.white)
                                .padding(.vertical, 8)
                        }

                        if !liveSearch.results.isEmpty {
                            liveResults
                        } else if query.isEmpty {
                            savedSection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Le tue città")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fine") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onChange(of: query) { value in
                liveSearch.update(value)
            }
        }
    }

    private var introCard: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 62, height: 62)
                Image(systemName: "map.fill")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Cerca e salva città")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("I risultati compaiono mentre scrivi. Apri una città e salvala dalla home.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }
            Spacer()
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 27, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        )
        .padding(.top, 10)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Scrivi una città…", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                    liveSearch.update("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    private var liveResults: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("Risultati in tempo reale", systemImage: "bolt.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.white)

            ForEach(liveSearch.results, id: \.self) { completion in
                Button {
                    resolving = true
                    Task {
                        if let candidate = await liveSearch.resolve(completion) {
                            await store.loadWeather(
                                latitude: candidate.latitude,
                                longitude: candidate.longitude,
                                city: candidate.name,
                                country: candidate.country,
                                timeZoneIdentifier: candidate.timeZoneIdentifier
                            )
                            dismiss()
                        }
                        resolving = false
                    }
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(completion.title)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Città salvate", systemImage: "star.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(store.savedCities.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.75))
            }

            if store.savedCities.isEmpty {
                VStack(spacing: 11) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 42))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("Nessuna città salvata")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("Cerca una città, aprila e premi la stella nella home.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            } else {
                ForEach(store.savedCities) { city in
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await store.loadWeather(
                                    latitude: city.latitude,
                                    longitude: city.longitude,
                                    city: city.city,
                                    country: city.country,
                                    timeZoneIdentifier: city.timeZoneIdentifier
                                )
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "location.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(city.city)
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                    Text(city.country)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.72))
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.removeSavedCity(city)
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.red.opacity(0.32), in: Circle())
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                }
            }
        }
    }
}
