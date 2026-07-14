import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WeatherStore
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var locationManager = LocationManager()
    @State private var showCities = false
    @State private var showSettings = false

    private var primary: Color { colorScheme == .dark ? .white : Color(red: 0.06, green: 0.13, blue: 0.24) }
    private var secondary: Color { primary.opacity(0.68) }
    private var cardFill: Color { colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.78) }
    private var border: Color { colorScheme == .dark ? Color.white.opacity(0.13) : Color.white.opacity(0.85) }

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherBackground(condition: store.current.condition)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        hero
                        hourlyForecast
                        detailsGrid
                        dailyForecast
                        updateFooter
                    }
                    .padding(.horizontal, 17)
                    .padding(.bottom, 34)
                }
                .refreshable { await refreshCurrent() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCities) { CitiesView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task {
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                    locationManager.authorizationStatus == .authorizedAlways {
                    locationManager.requestPermissionAndLocation()
                } else if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermissionAndLocation()
                } else {
                    await store.loadWeather(latitude: 41.9028, longitude: 12.4964, city: "Roma", country: "Italia")
                }
            }
            .overlay {
                if store.isLoading {
                    ZStack {
                        Color.black.opacity(0.12).ignoresSafeArea()
                        VStack(spacing: 14) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Aggiornamento meteo…")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 22)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
            }
            .alert("Dati meteo non disponibili", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("Riprova") {
                    Task { await refreshCurrent() }
                }
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .onChange(of: locationManager.location) { location in
                guard let location else { return }
                Task {
                    await store.loadWeather(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        city: locationManager.cityName ?? "Posizione attuale",
                        country: locationManager.countryName ?? ""
                    )
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { showCities = true } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(cardFill)
                        Image(systemName: "location.fill")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.current.city)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text(store.current.country)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(secondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(secondary)
                }
                .foregroundStyle(primary)
            }

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(primary)
                    .frame(width: 42, height: 42)
                    .background(cardFill, in: Circle())
                    .overlay(Circle().stroke(border, lineWidth: 1))
            }
        }
        .padding(.top, 10)
    }

    private var hero: some View {
        VStack(spacing: 13) {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: store.current.condition.symbol)
                    .font(.system(size: 78, weight: .medium))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(store.current.temperature.rounded()))°")
                        .font(.system(size: 86, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.75)
                    Text(store.current.condition.title)
                        .font(.title3.bold())
                }
            }

            Text(store.current.summary)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(secondary)
                .padding(.horizontal, 10)

            HStack(spacing: 8) {
                Label("Percepita \(Int(store.current.apparentTemperature.rounded()))°", systemImage: "thermometer.medium")
                Label("Max \(Int(store.current.daily.first?.high ?? store.current.temperature))°", systemImage: "arrow.up")
                Label("Min \(Int(store.current.daily.first?.low ?? store.current.temperature))°", systemImage: "arrow.down")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(primary)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(cardFill, in: Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 1))
        }
        .foregroundStyle(primary)
        .padding(.vertical, 8)
    }

    private var hourlyForecast: some View {
        WeatherCard(title: "Prossime ore", symbol: "clock.fill", fill: cardFill, border: border, primary: primary, secondary: secondary) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    ForEach(Array(store.current.hourly.prefix(12).enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 9) {
                            Text(index == 0 ? "Ora" : item.date.formatted(.dateTime.hour()))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(index == 0 ? primary : secondary)

                            Image(systemName: item.condition.symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.title2)

                            Text("\(Int(item.temperature.rounded()))°")
                                .font(.headline.bold())

                            Text(item.precipitationChance > 0.12 ? "\(Int(item.precipitationChance * 100))%" : " ")
                                .font(.caption2.bold())
                                .foregroundStyle(Color.blue)
                        }
                        .frame(width: 58)
                        .padding(.vertical, 10)
                        .background(index == 0 ? primary.opacity(colorScheme == .dark ? 0.12 : 0.07) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                }
            }
        }
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DetailTile(title: "Umidità", value: "\(Int(store.current.humidity * 100))%", symbol: "humidity.fill", subtitle: "Livello attuale", fill: cardFill, border: border, primary: primary, secondary: secondary)
            DetailTile(title: "Vento", value: "\(Int(store.current.windSpeed)) km/h", symbol: "wind", subtitle: "Velocità", fill: cardFill, border: border, primary: primary, secondary: secondary)
            DetailTile(title: "Indice UV", value: "\(store.current.uvIndex)", symbol: "sun.max.fill", subtitle: uvDescription, fill: cardFill, border: border, primary: primary, secondary: secondary)
            DetailTile(title: "Pressione", value: "\(Int(store.current.pressure)) hPa", symbol: "gauge.with.dots.needle.50percent", subtitle: "Atmosferica", fill: cardFill, border: border, primary: primary, secondary: secondary)
            DetailTile(title: "Visibilità", value: "\(Int(store.current.visibility)) km", symbol: "eye.fill", subtitle: "Distanza stimata", fill: cardFill, border: border, primary: primary, secondary: secondary)
            DetailTile(title: "Tramonto", value: store.current.sunset.formatted(date: .omitted, time: .shortened), symbol: "sunset.fill", subtitle: "Alba \(store.current.sunrise.formatted(date: .omitted, time: .shortened))", fill: cardFill, border: border, primary: primary, secondary: secondary)
        }
    }

    private var dailyForecast: some View {
        WeatherCard(title: "Previsioni 10 giorni", symbol: "calendar", fill: cardFill, border: border, primary: primary, secondary: secondary) {
            VStack(spacing: 0) {
                ForEach(Array(store.current.daily.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 9) {
                        Text(index == 0 ? "Oggi" : item.date.formatted(.dateTime.weekday(.wide)))
                            .font(.subheadline.weight(index == 0 ? .bold : .semibold))
                            .frame(width: 93, alignment: .leading)

                        Image(systemName: item.condition.symbol)
                            .symbolRenderingMode(.multicolor)
                            .font(.title3)
                            .frame(width: 32)

                        Text(item.precipitationChance > 0.12 ? "\(Int(item.precipitationChance * 100))%" : "")
                            .font(.caption.bold())
                            .foregroundStyle(Color.blue)
                            .frame(width: 38)

                        Spacer()

                        Text("\(Int(item.low))°")
                            .foregroundStyle(secondary)

                        ZStack(alignment: .leading) {
                            Capsule().fill(primary.opacity(0.10))
                            Capsule()
                                .fill(LinearGradient(colors: [.cyan, .yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                .frame(width: 30)
                        }
                        .frame(width: 50, height: 5)

                        Text("\(Int(item.high))°")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(primary)
                    .padding(.vertical, 12)

                    if index < store.current.daily.count - 1 {
                        Divider().overlay(primary.opacity(0.09))
                    }
                }
            }
        }
    }

    private var updateFooter: some View {
        VStack(spacing: 5) {
            Text(store.hasLoadedRealData ? "Dati meteo reali · Apple Weather" : "In attesa dei dati reali")
                .font(.caption.weight(.bold))
            Text("Aggiornato alle \(store.current.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
            
        }
        .foregroundStyle(secondary)
        .padding(.top, 2)
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
        await store.loadWeather(
            latitude: store.current.latitude,
            longitude: store.current.longitude,
            city: store.current.city,
            country: store.current.country
        )
    }
}

struct WeatherCard<Content: View>: View {
    let title: String
    let symbol: String
    let fill: Color
    let border: Color
    let primary: Color
    let secondary: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: symbol)
                .font(.caption.bold())
                .foregroundStyle(secondary)
            content
        }
        .foregroundStyle(primary)
        .padding(16)
        .background(fill, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.07), radius: 18, y: 9)
    }
}

struct DetailTile: View {
    let title: String
    let value: String
    let symbol: String
    let subtitle: String
    let fill: Color
    let border: Color
    let primary: Color
    let secondary: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .bold))
                    .symbolRenderingMode(.multicolor)
                Spacer()
            }

            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(secondary)

            Text(value)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
        .padding(15)
        .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 14, y: 7)
    }
}
