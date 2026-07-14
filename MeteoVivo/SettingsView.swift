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
                    LabeledContent("Fonte", value: store.hasLoadedRealData ? "Apple WeatherKit" : "Non disponibili")
                    Text("L’app utilizza esclusivamente dati meteo reali tramite Apple WeatherKit. WeatherKit deve essere attivo nell’App ID e nelle capability del progetto.")
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
