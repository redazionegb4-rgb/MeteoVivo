import Foundation

extension CityWeather {
    static func demo(city: String = "Roma", country: String = "Italia", latitude: Double = 41.9028, longitude: Double = 12.4964) -> CityWeather {
        let now = Date()
        let calendar = Calendar.current
        let hourlyConditions: [WeatherConditionKind] = [.clear, .clear, .partlyCloudy, .partlyCloudy, .cloudy, .rain, .rain, .partlyCloudy]
        let hourly = (0..<24).map { index in
            HourlyForecast(
                id: UUID(),
                date: calendar.date(byAdding: .hour, value: index, to: now) ?? now,
                temperature: 27 + sin(Double(index) / 3.0) * 4,
                precipitationChance: index >= 5 && index <= 8 ? 0.55 : 0.08,
                condition: hourlyConditions[index % hourlyConditions.count]
            )
        }
        let daily = (0..<10).map { index in
            DailyForecast(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: index, to: now) ?? now,
                low: 18 + Double(index % 3),
                high: 29 + Double(index % 4),
                precipitationChance: index == 2 || index == 6 ? 0.62 : 0.12,
                condition: index == 2 ? .rain : (index == 6 ? .thunderstorm : (index % 3 == 0 ? .partlyCloudy : .clear))
            )
        }
        return CityWeather(
            id: UUID(), city: city, country: country, latitude: latitude, longitude: longitude,
            temperature: 29, apparentTemperature: 31, condition: .clear,
            summary: "Cielo sereno per gran parte della giornata.", humidity: 0.48,
            windSpeed: 11, uvIndex: 7, pressure: 1015, visibility: 18,
            sunrise: calendar.date(bySettingHour: 5, minute: 47, second: 0, of: now) ?? now,
            sunset: calendar.date(bySettingHour: 20, minute: 43, second: 0, of: now) ?? now,
            hourly: hourly, daily: daily, lastUpdated: now
        )
    }
}
