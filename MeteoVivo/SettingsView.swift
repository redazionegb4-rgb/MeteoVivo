import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WeatherStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Aspetto") {
                    Picker("Tema", selection: Binding(get: { store.theme }, set: { store.theme = $0 })) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }

                Section("Dati meteo") {
                    LabeledContent("Fonte", value: store.useLiveWeather ? "Apple WeatherKit" : "Dati dimostrativi")
                    Text("Dopo aver attivato WeatherKit nell’account Apple Developer e in Signing & Capabilities, l’app utilizzerà automaticamente i dati reali.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Informazioni") {
                    LabeledContent("Versione", value: "1.0")
                }
            }
            .navigationTitle("Impostazioni")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { dismiss() }
                }
            }
        }
    }
}
