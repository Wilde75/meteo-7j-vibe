import SwiftUI

@main
struct Meteo7JoursApp: App {
    @StateObject private var cityStore = CityStore.shared
    @StateObject private var viewModel = WeatherViewModel.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ForecastView()
                .environmentObject(cityStore)
                .environmentObject(viewModel)
        } label: {
            Label(viewModel.menuBarTitle, systemImage: viewModel.menuBarIcon)
                .help("Météo du jour à \(viewModel.menuBarCityName.isEmpty ? "…" : viewModel.menuBarCityName) — cliquez pour les 7 prochains jours")
        }
        .menuBarExtraStyle(.window)
    }
}
