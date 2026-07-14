import SwiftUI

@main
struct MeteoVivoApp: App {
    @StateObject private var weatherStore = WeatherStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weatherStore)
                .preferredColorScheme(weatherStore.preferredColorScheme)
        }
    }
}
