import Foundation
import SwiftUI
import CoreLocation
import WeatherKit

@MainActor
final class WeatherStore: ObservableObject {
    @Published var current: CityWeather?
    @Published var favorites: [CityWeather] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedRealData = false
    @Published var lastRequestedLocation: (latitude: Double, longitude: Double, city: String, country: String)?
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.automatic.rawValue

    var theme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .automatic }
        set {
            appThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func loadWeather(latitude: Double, longitude: Double, city: String, country: String) async {
        lastRequestedLocation = (latitude, longitude, city, country)
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let weather = try await WeatherService.shared.weather(for: location)
            let now = Date()
            let currentWeather = weather.currentWeather

            let startOfCurrentHour = Calendar.current.date(
                bySetting: .minute,
                value: 0,
                of: now
            ) ?? now

            let hourly = weather.hourlyForecast.forecast
                .filter { $0.date >= startOfCurrentHour }
                .prefix(24)
                .map {
                    HourlyForecast(
                        id: UUID(),
                        date: $0.date,
                        temperature: $0.temperature.converted(to: .celsius).value,
                        precipitationChance: $0.precipitationChance,
                        condition: Self.mapCondition($0.condition)
                    )
                }

            let daily = weather.dailyForecast.forecast.prefix(10).map {
                DailyForecast(
                    id: UUID(),
                    date: $0.date,
                    low: $0.lowTemperature.converted(to: .celsius).value,
                    high: $0.highTemperature.converted(to: .celsius).value,
                    precipitationChance: $0.precipitationChance,
                    condition: Self.mapCondition($0.condition)
                )
            }

            current = CityWeather(
                id: UUID(),
                city: city,
                country: country,
                latitude: latitude,
                longitude: longitude,
                temperature: currentWeather.temperature.converted(to: .celsius).value,
                apparentTemperature: currentWeather.apparentTemperature.converted(to: .celsius).value,
                condition: Self.mapCondition(currentWeather.condition),
                summary: Self.localizedSummary(for: currentWeather.condition),
                humidity: currentWeather.humidity,
                windSpeed: currentWeather.wind.speed.converted(to: .kilometersPerHour).value,
                uvIndex: currentWeather.uvIndex.value,
                pressure: currentWeather.pressure.converted(to: .hectopascals).value,
                visibility: currentWeather.visibility.converted(to: .kilometers).value,
                sunrise: weather.dailyForecast.forecast.first?.sun.sunrise ?? now,
                sunset: weather.dailyForecast.forecast.first?.sun.sunset ?? now,
                hourly: Array(hourly),
                daily: Array(daily),
                lastUpdated: now
            )

            hasLoadedRealData = true
            updateFavoriteIfNeeded()
        } catch {
            current = nil
            hasLoadedRealData = false
            errorMessage = "WeatherKit non è ancora autorizzato per questa app. Attivalo nell’App ID e in Signing & Capabilities, poi reinstalla l’app."
        }
    }

    func retryLastRequest() async {
        guard let request = lastRequestedLocation else { return }
        await loadWeather(
            latitude: request.latitude,
            longitude: request.longitude,
            city: request.city,
            country: request.country
        )
    }

    func addCurrentToFavorites() {
        guard let current, hasLoadedRealData else { return }
        guard !favorites.contains(where: {
            abs($0.latitude - current.latitude) < 0.001 &&
            abs($0.longitude - current.longitude) < 0.001
        }) else { return }
        favorites.append(current)
    }

    func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
    }

    private func updateFavoriteIfNeeded() {
        guard let current else { return }
        guard let index = favorites.firstIndex(where: {
            abs($0.latitude - current.latitude) < 0.001 &&
            abs($0.longitude - current.longitude) < 0.001
        }) else { return }
        favorites[index] = current
    }

    private static func localizedSummary(for condition: WeatherCondition) -> String {
        switch mapCondition(condition) {
        case .clear: return "Cielo sereno e condizioni piacevoli"
        case .partlyCloudy: return "Sole alternato a qualche nuvola"
        case .cloudy: return "Cielo prevalentemente nuvoloso"
        case .rain: return "Precipitazioni previste nella zona"
        case .thunderstorm: return "Possibili temporali: presta attenzione"
        case .snow: return "Possibili nevicate nella zona"
        case .fog: return "Visibilità ridotta per nebbia o foschia"
        case .wind: return "Vento sostenuto nella zona"
        }
    }

    private static func mapCondition(_ condition: WeatherCondition) -> WeatherConditionKind {
        let text = String(describing: condition).lowercased()
        if text.contains("thunder") || text.contains("storm") { return .thunderstorm }
        if text.contains("snow") || text.contains("sleet") || text.contains("blizzard") || text.contains("flurr") { return .snow }
        if text.contains("rain") || text.contains("drizzle") || text.contains("shower") { return .rain }
        if text.contains("fog") || text.contains("haze") || text.contains("smok") { return .fog }
        if text.contains("wind") || text.contains("breez") { return .wind }
        if text.contains("partly") || text.contains("mostlyclear") || text.contains("mostly clear") { return .partlyCloudy }
        if text.contains("cloud") || text.contains("overcast") { return .cloudy }
        return .clear
    }
}
