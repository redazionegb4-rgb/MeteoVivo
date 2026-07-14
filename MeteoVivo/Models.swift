import Foundation
import CoreLocation

struct CityWeather: Identifiable, Codable, Hashable {
    let id: UUID
    var city: String
    var country: String
    var latitude: Double
    var longitude: Double
    var temperature: Double
    var apparentTemperature: Double
    var condition: WeatherConditionKind
    var summary: String
    var humidity: Double
    var windSpeed: Double
    var uvIndex: Int
    var pressure: Double
    var visibility: Double
    var sunrise: Date
    var sunset: Date
    var hourly: [HourlyForecast]
    var daily: [DailyForecast]
    var lastUpdated: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct HourlyForecast: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let temperature: Double
    let precipitationChance: Double
    let condition: WeatherConditionKind
}

struct DailyForecast: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let low: Double
    let high: Double
    let precipitationChance: Double
    let condition: WeatherConditionKind
}

enum WeatherConditionKind: String, Codable, CaseIterable {
    case clear, partlyCloudy, cloudy, rain, thunderstorm, snow, fog, wind

    var title: String {
        switch self {
        case .clear: return "Sereno"
        case .partlyCloudy: return "Poco nuvoloso"
        case .cloudy: return "Nuvoloso"
        case .rain: return "Pioggia"
        case .thunderstorm: return "Temporale"
        case .snow: return "Neve"
        case .fog: return "Nebbia"
        case .wind: return "Ventoso"
        }
    }

    var symbol: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        case .wind: return "wind"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case automatic = "Automatico"
    case light = "Chiaro"
    case dark = "Scuro"
    var id: String { rawValue }
}
