import Foundation
import SwiftUI
import CoreLocation
import WeatherKit

@MainActor
final class WeatherStore: ObservableObject {
    @Published var current: CityWeather?
    @Published var savedCities: [SavedCity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedRealData = false
    @Published var weatherMarkLightURL: URL?
    @Published var weatherMarkDarkURL: URL?
    @Published var weatherLegalURL: URL?
    @Published var lastRequestedLocation: (latitude: Double, longitude: Double, city: String, country: String, timeZoneIdentifier: String)?

    @AppStorage("appTheme") private var appThemeRaw = AppTheme.automatic.rawValue
    private let savedCitiesKey = "savedCitiesV2"

    init() {
        loadSavedCities()

        Task {
            await loadWeatherAttribution()
        }
    }

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

    func loadWeatherAttribution() async {
        do {
            let attribution = try await WeatherService.shared.attribution
            weatherMarkLightURL = attribution.combinedMarkLightURL
            weatherMarkDarkURL = attribution.combinedMarkDarkURL
            weatherLegalURL = attribution.legalPageURL
        } catch {
            // L'attribuzione verrà richiesta nuovamente al prossimo caricamento.
        }
    }

    func loadWeather(
        latitude: Double,
        longitude: Double,
        city: String,
        country: String,
        timeZoneIdentifier: String? = nil
    ) async {
        let geocodedTimeZone = await resolveTimeZone(
            latitude: latitude,
            longitude: longitude
        )

        let resolvedTimeZone: String
        if geocodedTimeZone != TimeZone.current.identifier {
            resolvedTimeZone = geocodedTimeZone
        } else if let timeZoneIdentifier, !timeZoneIdentifier.isEmpty {
            resolvedTimeZone = timeZoneIdentifier
        } else {
            resolvedTimeZone = geocodedTimeZone
        }
        lastRequestedLocation = (latitude, longitude, city, country, resolvedTimeZone)
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let weather = try await WeatherService.shared.weather(for: location)
            let now = Date()
            let currentWeather = weather.currentWeather
            let calendar = Calendar(identifier: .gregorian)
            let startOfCurrentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now

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
                timeZoneIdentifier: resolvedTimeZone,
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

            if weatherLegalURL == nil {
                await loadWeatherAttribution()
            }
        } catch {
            current = nil
            hasLoadedRealData = false
            errorMessage = "Non è stato possibile caricare i dati meteo reali. Riprova tra qualche secondo."
        }
    }

    func retryLastRequest() async {
        guard let request = lastRequestedLocation else { return }
        await loadWeather(
            latitude: request.latitude,
            longitude: request.longitude,
            city: request.city,
            country: request.country,
            timeZoneIdentifier: request.timeZoneIdentifier
        )
    }

    func isSaved(latitude: Double, longitude: Double) -> Bool {
        savedCities.contains {
            abs($0.latitude - latitude) < 0.001 &&
            abs($0.longitude - longitude) < 0.001
        }
    }

    func saveCurrentCity() {
        guard let current else { return }
        saveCity(
            city: current.city,
            country: current.country,
            latitude: current.latitude,
            longitude: current.longitude,
            timeZoneIdentifier: current.timeZoneIdentifier
        )
    }

    func saveCity(
        city: String,
        country: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String
    ) {
        guard !isSaved(latitude: latitude, longitude: longitude) else { return }

        savedCities.append(
            SavedCity(
                id: UUID(),
                city: city,
                country: country,
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: timeZoneIdentifier
            )
        )
        persistSavedCities()
    }

    func removeSavedCity(_ city: SavedCity) {
        savedCities.removeAll { $0.id == city.id }
        persistSavedCities()
    }

    private func loadSavedCities() {
        guard
            let data = UserDefaults.standard.data(forKey: savedCitiesKey),
            let decoded = try? JSONDecoder().decode([SavedCity].self, from: data)
        else { return }
        savedCities = decoded
    }

    private func persistSavedCities() {
        guard let data = try? JSONEncoder().encode(savedCities) else { return }
        UserDefaults.standard.set(data, forKey: savedCitiesKey)
    }

    private func resolveTimeZone(latitude: Double, longitude: Double) async -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: "it_IT")
            )

            if let identifier = placemarks.first?.timeZone?.identifier,
               !identifier.isEmpty {
                return identifier
            }
        } catch {
            // Il fallback viene gestito dal chiamante.
        }

        return TimeZone.current.identifier
    }

    private static func localizedSummary(for condition: WeatherCondition) -> String {
        switch mapCondition(condition) {
        case .clear: return "Cielo sereno e condizioni piacevoli"
        case .partlyCloudy: return "Sole alternato a qualche nuvola"
        case .cloudy: return "Cielo prevalentemente nuvoloso"
        case .rain: return "Pioggia prevista nella zona"
        case .thunderstorm: return "Possibili temporali nella zona"
        case .snow: return "Possibili nevicate nella zona"
        case .fog: return "Visibilità ridotta per nebbia o foschia"
        case .wind: return "Vento sostenuto nella zona"
        case .hail: return "Possibili precipitazioni di grandine"
        case .sleet: return "Possibili precipitazioni miste"
        }
    }

    private static func mapCondition(_ condition: WeatherCondition) -> WeatherConditionKind {
        switch condition {
        case .blizzard, .blowingSnow, .flurries, .heavySnow, .snow, .sunFlurries:
            return .snow
        case .drizzle, .freezingDrizzle, .freezingRain, .heavyRain, .rain, .sunShowers:
            return .rain
        case .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .thunderstorms, .tropicalStorm, .hurricane:
            return .thunderstorm
        case .foggy, .haze, .smoky, .blowingDust:
            return .fog
        case .breezy, .windy:
            return .wind
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .mostlyClear, .partlyCloudy:
            return .partlyCloudy
        case .hail:
            return .hail
        case .sleet, .wintryMix:
            return .sleet
        case .clear, .hot, .frigid:
            return .clear
        @unknown default:
            return .cloudy
        }
    }
}
