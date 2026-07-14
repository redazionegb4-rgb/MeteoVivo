import SwiftUI
import CoreLocation

struct CitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WeatherStore
    @StateObject private var locationManager = LocationManager()
    @State private var query = ""
    @State private var results: [CLPlacemark] = []
    @State private var searching = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        locationManager.requestPermissionAndLocation()
                    } label: {
                        Label("Usa la mia posizione", systemImage: "location.fill")
                    }
                }

                if !results.isEmpty {
                    Section("Risultati") {
                        ForEach(results, id: \.self) { placemark in
                            Button {
                                select(placemark)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(placemark.locality ?? placemark.name ?? "Località")
                                    Text([placemark.administrativeArea, placemark.country].compactMap { $0 }.joined(separator: ", "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Città rapide") {
                    quickCity("Roma", "Italia", 41.9028, 12.4964)
                    quickCity("Milano", "Italia", 45.4642, 9.1900)
                    quickCity("Napoli", "Italia", 40.8518, 14.2681)
                    quickCity("Torino", "Italia", 45.0703, 7.6869)
                    quickCity("Palermo", "Italia", 38.1157, 13.3615)
                }

                if !store.favorites.isEmpty {
                    Section("Preferite") {
                        ForEach(store.favorites) { city in
                            Button {
                                Task {
                                    await store.loadWeather(latitude: city.latitude, longitude: city.longitude, city: city.city, country: city.country)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(city.city)
                                        Text(city.country).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(city.temperature))°")
                                }
                            }
                        }
                        .onDelete(perform: store.removeFavorite)
                    }
                }
            }
            .navigationTitle("Città")
            .searchable(text: $query, prompt: "Cerca una città")
            .onSubmit(of: .search) { search() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Chiudi") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.addCurrentToFavorites() } label: { Image(systemName: "star") }
                }
            }
            .overlay { if searching { ProgressView("Ricerca…") } }
            .onChange(of: locationManager.location) { location in
                guard let location else { return }
                Task {
                    await store.loadWeather(latitude: location.coordinate.latitude,
                                            longitude: location.coordinate.longitude,
                                            city: locationManager.cityName ?? "Posizione attuale",
                                            country: locationManager.countryName ?? "")
                    dismiss()
                }
            }
        }
    }

    private func quickCity(_ city: String, _ country: String, _ lat: Double, _ lon: Double) -> some View {
        Button {
            Task {
                await store.loadWeather(latitude: lat, longitude: lon, city: city, country: country)
                dismiss()
            }
        } label: {
            Label(city, systemImage: "building.2.fill")
        }
    }

    private func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        searching = true
        CLGeocoder().geocodeAddressString(query) { placemarks, _ in
            DispatchQueue.main.async {
                results = placemarks ?? []
                searching = false
            }
        }
    }

    private func select(_ placemark: CLPlacemark) {
        guard let location = placemark.location else { return }
        Task {
            await store.loadWeather(latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude,
                                    city: placemark.locality ?? placemark.name ?? query,
                                    country: placemark.country ?? "")
            dismiss()
        }
    }
}
