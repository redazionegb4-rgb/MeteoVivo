import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WeatherStore
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var locationManager = LocationManager()
    @State private var showCities = false
    @State private var showSettings = false

    private func primaryColor(for weather: CityWeather) -> Color {
        if !weather.isDaytime {
            return .white
        }
        return colorScheme == .dark
            ? .white
            : Color(red: 0.04, green: 0.10, blue: 0.20)
    }

    private func secondaryColor(for weather: CityWeather) -> Color {
        primaryColor(for: weather).opacity(0.72)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if let weather = store.current {
                    WeatherBackground(condition: weather.condition, isDaytime: weather.isDaytime)
                    weatherContent(weather)
                } else {
                    setupBackground
                    setupView
                }

                if store.isLoading {
                    loadingOverlay
                }
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
                    await store.loadWeather(
                        latitude: 41.9028,
                        longitude: 12.4964,
                        city: "Roma",
                        country: "Italia"
                    )
                }
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

    private var setupBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.03, green: 0.08, blue: 0.18),
                       Color(red: 0.12, green: 0.16, blue: 0.35),
                       Color(red: 0.24, green: 0.08, blue: 0.36)]
                    : [Color(red: 0.28, green: 0.84, blue: 1.0),
                       Color(red: 0.52, green: 0.50, blue: 0.98),
                       Color(red: 0.98, green: 0.40, blue: 0.67)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.yellow.opacity(0.55))
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: 150, y: -310)

            Circle()
                .fill(Color.cyan.opacity(0.28))
                .frame(width: 250, height: 250)
                .blur(radius: 40)
                .offset(x: -160, y: 330)
        }
    }

    private var setupView: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 138, height: 138)
                    .overlay(
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 28, y: 18)

                Image(systemName: "cloud.sun.rain.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .yellow, .cyan)
                    .font(.system(size: 64, weight: .semibold))
            }

            VStack(spacing: 10) {
                Text("Attiva il meteo reale")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("WeatherKit non è ancora autorizzato per questa app. I dati dimostrativi sono stati rimossi: qui compariranno solo informazioni meteo reali.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            VStack(spacing: 12) {
                step(number: "1", text: "Attiva WeatherKit nell’App ID su Apple Developer")
                step(number: "2", text: "Aggiungi WeatherKit in Signing & Capabilities")
                step(number: "3", text: "Elimina l’app dall’iPhone e reinstallala")
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Button {
                Task { await store.retryLastRequest() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                    Text("Riprova")
                }
                .font(.headline.bold())
                .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.24))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.16), radius: 18, y: 10)
            }
            .padding(.horizontal, 20)

            Button {
                showSettings = true
            } label: {
                Text("Apri impostazioni")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.top, 32)
        .padding(.bottom, 28)
    }

    private func step(number: String, text: String) -> some View {
        HStack(spacing: 13) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(Color(red: 0.08, green: 0.10, blue: 0.22))
                .frame(width: 30, height: 30)
                .background(Color.white, in: Circle())

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.16).ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.25)

                Text("Caricamento meteo reale…")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func weatherContent(_ weather: CityWeather) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header(weather)
                hero(weather)
                hourlyForecast(weather)
                detailsGrid(weather)
                dailyForecast(weather)
                updateFooter(weather)
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 34)
        }
        .refreshable {
            await store.loadWeather(
                latitude: weather.latitude,
                longitude: weather.longitude,
                city: weather.city,
                country: weather.country
            )
        }
    }

    private func header(_ weather: CityWeather) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(weather.city)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(weather.country)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(secondaryColor(for: weather))
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        Text("Ora locale \(localTime(weather))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(secondaryColor(for: weather))
                    }
                }
            }
            .foregroundStyle(primaryColor(for: weather))

            Spacer()

            Button {
                locationManager.requestPermissionAndLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(primaryColor(for: weather))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Button {
                store.saveCurrentCity()
            } label: {
                Image(systemName: store.isSaved(latitude: weather.latitude, longitude: weather.longitude) ? "star.fill" : "star")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(store.isSaved(latitude: weather.latitude, longitude: weather.longitude) ? Color.yellow : primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Button { showCities = true } label: {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(primaryColor(for: weather))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(primaryColor(for: weather))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.top, 10)
    }

    private func hero(_ weather: CityWeather) -> some View {
        VStack(spacing: 13) {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: weather.condition.symbol(isDaytime: weather.isDaytime))
                    .font(.system(size: 78, weight: .medium))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: Color.black.opacity(0.14), radius: 18, y: 8)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(weather.temperature.rounded()))°")
                        .font(.system(size: 86, weight: .semibold, design: .rounded))
                    Text(weather.condition.title)
                        .font(.title3.bold())
                }
            }

            AnimatedWeatherBadge(
                condition: weather.condition,
                isDaytime: weather.isDaytime
            )

            Text(weather.summary)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(secondaryColor(for: weather))

            HStack(spacing: 8) {
                Label("Percepita \(Int(weather.apparentTemperature.rounded()))°", systemImage: "thermometer.medium")
                if let first = weather.daily.first {
                    Label("Max \(Int(first.high))°", systemImage: "arrow.up")
                    Label("Min \(Int(first.low))°", systemImage: "arrow.down")
                }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(primaryColor(for: weather))
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(primaryColor(for: weather))
        .padding(.vertical, 8)
    }

    private func hourlyForecast(_ weather: CityWeather) -> some View {
        WeatherCard(title: "Prossime ore", symbol: "clock.fill") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    ForEach(Array(weather.hourly.prefix(12).enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 9) {
                            Text(index == 0 ? "ORA" : hourText(item.date, timeZone: weather.timeZone))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(index == 0 ? primary : secondary)

                            Image(systemName: item.condition.symbol(isDaytime: isDaytime(item.date, weather: weather)))
                                .symbolRenderingMode(.multicolor)
                                .font(.title2)

                            Text("\(Int(item.temperature.rounded()))°")
                                .font(.headline.bold())

                            Text(item.precipitationChance > 0.12 ? "\(Int(item.precipitationChance * 100))%" : " ")
                                .font(.caption2.bold())
                                .foregroundStyle(.blue)
                        }
                        .frame(width: 58)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    private func detailsGrid(_ weather: CityWeather) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DetailTile(title: "Umidità", value: "\(Int(weather.humidity * 100))%", symbol: "humidity.fill", subtitle: "Livello attuale")
            DetailTile(title: "Vento", value: "\(Int(weather.windSpeed)) km/h", symbol: "wind", subtitle: "Velocità")
            DetailTile(title: "Indice UV", value: "\(weather.uvIndex)", symbol: "sun.max.fill", subtitle: uvDescription(weather.uvIndex))
            DetailTile(title: "Pressione", value: "\(Int(weather.pressure)) hPa", symbol: "gauge.with.dots.needle.50percent", subtitle: "Atmosferica")
            DetailTile(title: "Visibilità", value: "\(Int(weather.visibility)) km", symbol: "eye.fill", subtitle: "Distanza stimata")
            DetailTile(title: "Tramonto", value: weather.sunset.formatted(date: .omitted, time: .shortened), symbol: "sunset.fill", subtitle: "Alba \(weather.sunrise.formatted(date: .omitted, time: .shortened))")
        }
    }

    private func dailyForecast(_ weather: CityWeather) -> some View {
        WeatherCard(title: "Previsioni 10 giorni", symbol: "calendar") {
            VStack(spacing: 0) {
                ForEach(Array(weather.daily.enumerated()), id: \.element.id) { index, item in
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
                            .foregroundStyle(.blue)
                            .frame(width: 38)

                        Spacer()

                        Text("\(Int(item.low))°").foregroundStyle(secondaryColor(for: weather))
                        Capsule()
                            .fill(LinearGradient(colors: [.cyan, .yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 48, height: 5)
                        Text("\(Int(item.high))°").fontWeight(.bold)
                    }
                    .foregroundStyle(primaryColor(for: weather))
                    .padding(.vertical, 12)

                    if index < weather.daily.count - 1 {
                        Divider().overlay(primary.opacity(0.09))
                    }
                }
            }
        }
    }

    private func updateFooter(_ weather: CityWeather) -> some View {
        VStack(spacing: 5) {
            Text("Dati meteo reali · Apple Weather")
                .font(.caption.weight(.bold))
            Text("Aggiornato alle \(weather.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
        }
        .foregroundStyle(secondaryColor(for: weather))
        .padding(.top, 2)
    }

    private func hourText(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func localTime(_ weather: CityWeather) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.timeZone = weather.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private func isDaytime(_ date: Date, weather: CityWeather) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let timeZone = weather.timeZone
        var localCalendar = calendar
        localCalendar.timeZone = timeZone

        let hour = localCalendar.component(.hour, from: date)
        return hour >= 6 && hour < 20
    }

    private func uvDescription(_ value: Int) -> String {
        switch value {
        case 0...2: return "Basso"
        case 3...5: return "Moderato"
        case 6...7: return "Alto"
        case 8...10: return "Molto alto"
        default: return "Estremo"
        }
    }
}

struct WeatherCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: symbol)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .background(
            Color.black.opacity(0.16),
            in: RoundedRectangle(cornerRadius: 27, style: .continuous)
        )
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 27, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .stroke(Color.white.opacity(0.46), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.09), radius: 18, y: 10)
    }
}

struct DetailTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let symbol: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.multicolor)

            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
        .padding(15)
        .background(
            Color.black.opacity(0.14),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, y: 8)
    }
}


private struct AnimatedWeatherBadge: View {
    let condition: WeatherConditionKind
    let isDaytime: Bool
    @State private var animate = false

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.14))
                .frame(height: 44)

            HStack(spacing: 10) {
                Image(systemName: condition.symbol(isDaytime: isDaytime))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 21, weight: .bold))
                    .rotationEffect(.degrees(condition == .wind && animate ? 10 : 0))
                    .offset(y: verticalOffset)

                Text(animationText)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            if condition == .rain || condition == .thunderstorm {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(Color.cyan.opacity(0.75))
                        .frame(width: 2, height: 10)
                        .offset(
                            x: CGFloat(index * 22 - 77),
                            y: animate ? 17 : -17
                        )
                        .animation(
                            .linear(duration: 0.9)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.08),
                            value: animate
                        )
                }
            }

            if condition == .snow || condition == .sleet {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "snowflake")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.85))
                        .offset(
                            x: CGFloat(index * 26 - 65),
                            y: animate ? 16 : -16
                        )
                        .animation(
                            .linear(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.12),
                            value: animate
                        )
                }
            }
        }
        .frame(maxWidth: 250)
        .onAppear { animate = true }
    }

    private var verticalOffset: CGFloat {
        switch condition {
        case .clear, .partlyCloudy:
            return animate ? -2 : 2
        case .wind:
            return 0
        default:
            return animate ? 2 : -2
        }
    }

    private var animationText: String {
        switch condition {
        case .clear: return isDaytime ? "Sole in movimento" : "Cielo stellato"
        case .partlyCloudy: return isDaytime ? "Nuvole leggere" : "Nuvole notturne"
        case .cloudy: return "Nuvole in movimento"
        case .rain: return "Pioggia animata"
        case .thunderstorm: return "Temporale con lampi"
        case .snow: return "Neve animata"
        case .hail: return "Grandine animata"
        case .sleet: return "Nevischio animato"
        case .fog: return "Nebbia in movimento"
        case .wind: return "Raffiche animate"
        }
    }
}
