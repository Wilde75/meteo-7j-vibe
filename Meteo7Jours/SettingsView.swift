import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var cityStore: CityStore
    @Environment(\.dismiss) private var dismiss

    @State private var token = ""
    @State private var tokenStatus: String?
    @State private var query = ""
    @State private var results: [Place] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?

    var body: some View {
        Form {
            Section("Connexion Météo-France") {
                SecureField("Jeton d'accès (token)", text: $token)
                Button("Enregistrer le jeton") {
                    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        tokenStatus = "Le jeton est vide."
                        return
                    }
                    do {
                        try KeychainStore.saveToken(trimmed)
                        tokenStatus = "Jeton enregistré dans le trousseau."
                    } catch {
                        tokenStatus = "Erreur : \(error.localizedDescription)"
                    }
                }
                if let tokenStatus {
                    Text(tokenStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Créez un compte gratuit sur [portail-api.meteofrance.fr](https://portail-api.meteofrance.fr/web/fr/), puis générez un jeton d'accès longue durée dans « Mes API ». Le jeton reste stocké localement dans votre trousseau.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Mes villes") {
                HStack {
                    TextField("Ville ou code postal…", text: $query)
                        .onSubmit { Task { await search() } }
                    Button("Rechercher") {
                        Task { await search() }
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                }
                if isSearching {
                    ProgressView().controlSize(.small)
                }
                if let searchError {
                    Text(searchError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                ForEach(results) { place in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name).bold()
                            Text(place.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Ajouter") {
                            cityStore.addCity(from: place)
                        }
                    }
                }
                List {
                    ForEach(cityStore.cities) { city in
                        HStack {
                            Image(systemName: city.isDefault ? "house.fill" : "mappin.and.ellipse")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.name)
                                Text(city.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !city.isDefault {
                                Button("Domicile") {
                                    cityStore.setDefault(city)
                                }
                            }
                            Button(role: .destructive) {
                                cityStore.remove(city)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 200)
            }

            Section("Général") {
                Toggle("Ouvrir au démarrage", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            launchError = nil
                        } catch {
                            launchError = error.localizedDescription
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                if let launchError {
                    Text(launchError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack {
                Spacer()
                Button("Fermer") { dismiss() }
            }
        }
        .frame(width: 480)
        .padding(12)
        .onAppear {
            token = (try? KeychainStore.loadToken()) ?? ""
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            results = try await MeteoFranceClient.shared.searchPlaces(trimmed)
        } catch {
            results = []
            if let localized = error as? LocalizedError {
                searchError = localized.errorDescription ?? error.localizedDescription
            } else {
                searchError = error.localizedDescription
            }
        }
    }
}
