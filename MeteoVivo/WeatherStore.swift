import Foundation
import SwiftUI
import CoreLocation
#if canImport(WeatherKit)
import WeatherKit
#endif

@MainActor
final class WeatherStore: ObservableObject {
    @Published var current: CityWeather = .demo()
    @Published var favorites: [CityWeather] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var useLiveWeather = false
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.automatic.rawValue

    var theme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .automatic }
        set { appThemeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func loadDemo(city: String, country: String, latitude: Double, longitude: Double) {
        current = .demo(city: city, country: country, latitude: latitude, longitude: longitude)
        useLiveWeather = false
    }

    func loadWeather(latitude: Double, longitude: Double, city: String, country: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if canImport(WeatherKit)
        do {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let weather = try await WeatherService.shared.weather(for: location)
            let now = Date()
            let currentWeather = weather.currentWeather
            let hourly = weather.hourlyForecast.forecast.prefix(24).map {
                HourlyForecast(id: UUID(), date: $0.date, temperature: $0.temperature.converted(to: .celsius).value,
                               precipitationChance: $0.precipitationChance,
                               condition: Self.mapCondition($0.condition))
            }
            let daily = weather.dailyForecast.forecast.prefix(10).map {
                DailyForecast(id: UUID(), date: $0.date,
                              low: $0.lowTemperature.converted(to: .celsius).value,
                              high: $0.highTemperature.converted(to: .celsius).value,
                              precipitationChance: $0.precipitationChance,
                              condition: Self.mapCondition($0.condition))
            }
            current = CityWeather(
                id: UUID(), city: city, country: country, latitude: latitude, longitude: longitude,
                temperature: currentWeather.temperature.converted(to: .celsius).value,
                apparentTemperature: currentWeather.apparentTemperature.converted(to: .celsius).value,
                condition: Self.mapCondition(currentWeather.condition),
                summary: currentWeather.condition.description,
                humidity: currentWeather.humidity,
                windSpeed: currentWeather.wind.speed.converted(to: .kilometersPerHour).value,
                uvIndex: currentWeather.uvIndex.value,
                pressure: currentWeather.pressure.converted(to: .hectopascals).value,
                visibility: currentWeather.visibility.converted(to: .kilometers).value,
                sunrise: weather.dailyForecast.forecast.first?.sun.sunrise ?? now,
                sunset: weather.dailyForecast.forecast.first?.sun.sunset ?? now,
                hourly: Array(hourly), daily: Array(daily), lastUpdated: now
            )
            useLiveWeather = true
        } catch {
            errorMessage = "WeatherKit non è ancora configurato oppure non è disponibile: \(error.localizedDescription)"
            current = .demo(city: city, country: country, latitude: latitude, longitude: longitude)
            useLiveWeather = false
        }
        #else
        current = .demo(city: city, country: country, latitude: latitude, longitude: longitude)
        useLiveWeather = false
        #endif
    }

    func addCurrentToFavorites() {
        guard !favorites.contains(where: { $0.city.caseInsensitiveCompare(current.city) == .orderedSame }) else { return }
        favorites.append(current)
    }

    func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
    }

    private static func mapCondition(_ condition: WeatherCondition) -> WeatherConditionKind {
        let text = condition.description.lowercased()
        if text.contains("tempor") || text.contains("thunder") || text.contains("storm") { return .thunderstorm }
        if text.contains("neve") || text.contains("snow") || text.contains("sleet") || text.contains("blizzard") { return .snow }
        if text.contains("piogg") || text.contains("rain") || text.contains("drizzle") || text.contains("shower") { return .rain }
        if text.contains("nebb") || text.contains("fog") || text.contains("haze") || text.contains("smok") { return .fog }
        if text.contains("vento") || text.contains("wind") || text.contains("breez") { return .wind }
        if text.contains("parzial") || text.contains("partly") || text.contains("mostly clear") { return .partlyCloudy }
        if text.contains("nuvol") || text.contains("cloud") || text.contains("coperto") { return .cloudy }
        return .clear
    }
}
