import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WeatherStore
    @StateObject private var locationManager = LocationManager()
    @State private var showCities = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherBackground(condition: store.current.condition)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        currentWeather
                        hourlyForecast
                        detailsGrid
                        dailyForecast
                        updateFooter
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
                .refreshable {
                    await refreshCurrent()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCities) { CitiesView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task {
                if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    locationManager.requestPermissionAndLocation()
                }
            }
            .onChange(of: locationManager.location) { location in
                guard let location else { return }
                Task {
                    await store.loadWeather(latitude: location.coordinate.latitude,
                                            longitude: location.coordinate.longitude,
                                            city: locationManager.cityName ?? "Posizione attuale",
                                            country: locationManager.countryName ?? "")
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { showCities = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.current.city).font(.headline)
                        Text(store.current.country).font(.caption).opacity(0.8)
                    }
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .foregroundStyle(.white)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.top, 10)
    }

    private var currentWeather: some View {
        VStack(spacing: 8) {
            Image(systemName: store.current.condition.symbol)
                .font(.system(size: 70))
                .symbolRenderingMode(.multicolor)
                .shadow(radius: 10)
            Text("\(Int(store.current.temperature.rounded()))°")
                .font(.system(size: 92, weight: .thin, design: .rounded))
            Text(store.current.condition.title)
                .font(.title2.bold())
            Text(store.current.summary)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .opacity(0.88)
            Text("Percepita \(Int(store.current.apparentTemperature.rounded()))°")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(.white)
        .padding(.vertical, 6)
    }

    private var hourlyForecast: some View {
        WeatherCard(title: "PROSSIME ORE", symbol: "clock.fill") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(store.current.hourly) { item in
                        VStack(spacing: 9) {
                            Text(item.date, format: .dateTime.hour().minute())
                                .font(.caption.weight(.semibold))
                            Image(systemName: item.condition.symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.title2)
                            Text("\(Int(item.temperature.rounded()))°").font(.headline)
                            if item.precipitationChance > 0.15 {
                                Text("\(Int(item.precipitationChance * 100))%")
                                    .font(.caption2).foregroundStyle(.cyan)
                            }
                        }
                        .frame(width: 52)
                    }
                }
            }
        }
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            DetailTile(title: "UMIDITÀ", value: "\(Int(store.current.humidity * 100))%", symbol: "humidity.fill", subtitle: "Livello attuale")
            DetailTile(title: "VENTO", value: "\(Int(store.current.windSpeed)) km/h", symbol: "wind", subtitle: "Velocità")
            DetailTile(title: "INDICE UV", value: "\(store.current.uvIndex)", symbol: "sun.max.fill", subtitle: uvDescription)
            DetailTile(title: "PRESSIONE", value: "\(Int(store.current.pressure)) hPa", symbol: "gauge.with.dots.needle.50percent", subtitle: "Pressione atmosferica")
            DetailTile(title: "VISIBILITÀ", value: "\(Int(store.current.visibility)) km", symbol: "eye.fill", subtitle: "Distanza stimata")
            DetailTile(title: "SOLE", value: store.current.sunset.formatted(date: .omitted, time: .shortened), symbol: "sunset.fill", subtitle: "Alba \(store.current.sunrise.formatted(date: .omitted, time: .shortened))")
        }
    }

    private var dailyForecast: some View {
        WeatherCard(title: "PREVISIONI 10 GIORNI", symbol: "calendar") {
            VStack(spacing: 0) {
                ForEach(Array(store.current.daily.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Text(index == 0 ? "Oggi" : item.date.formatted(.dateTime.weekday(.wide)))
                            .frame(width: 90, alignment: .leading)
                        Image(systemName: item.condition.symbol)
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 34)
                        if item.precipitationChance > 0.15 {
                            Text("\(Int(item.precipitationChance * 100))%")
                                .font(.caption).foregroundStyle(.cyan)
                                .frame(width: 40)
                        } else { Spacer().frame(width: 40) }
                        Spacer()
                        Text("\(Int(item.low))°").opacity(0.65)
                        Capsule().fill(.white.opacity(0.35)).frame(width: 46, height: 4)
                        Text("\(Int(item.high))°").fontWeight(.semibold)
                    }
                    .padding(.vertical, 11)
                    if index < store.current.daily.count - 1 { Divider().overlay(.white.opacity(0.16)) }
                }
            }
        }
    }

    private var updateFooter: some View {
        VStack(spacing: 6) {
            Text(store.useLiveWeather ? "Dati WeatherKit" : "Modalità dimostrativa")
                .font(.caption.weight(.semibold))
            Text("Aggiornato \(store.current.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
            if let message = store.errorMessage {
                Text(message).font(.caption2).multilineTextAlignment(.center).padding(.top, 4)
            }
        }
        .foregroundStyle(.white.opacity(0.8))
    }

    private var uvDescription: String {
        switch store.current.uvIndex {
        case 0...2: return "Basso"
        case 3...5: return "Moderato"
        case 6...7: return "Alto"
        case 8...10: return "Molto alto"
        default: return "Estremo"
        }
    }

    private func refreshCurrent() async {
        await store.loadWeather(latitude: store.current.latitude, longitude: store.current.longitude,
                                city: store.current.city, country: store.current.country)
    }
}

struct WeatherCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.caption.bold()).foregroundStyle(.white.opacity(0.72))
            content
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12)))
    }
}

struct DetailTile: View {
    let title: String
    let value: String
    let symbol: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.caption.bold()).opacity(0.75)
            Text(value).font(.title2.bold())
            Text(subtitle).font(.caption).opacity(0.72).lineLimit(2)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(15)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12)))
    }
}
