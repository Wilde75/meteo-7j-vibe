import Foundation

final class WeatherViewModel: ObservableObject {
    static let shared = WeatherViewModel(cityStore: .shared)

    @Published var daily: [DailyForecast] = []
    @Published var current: HourlyForecast?
    @Published var observation: Observation?
    @Published var menuBarTemperature: Double?
    @Published var menuBarIcon = "cloud.sun"
    @Published var menuBarCityName = ""
    @Published var isLoading = false
    @Published var message: String?
    @Published var lastUpdate: Date?

    private let cityStore: CityStore
    private let client = MeteoFranceClient.shared

    init(cityStore: CityStore) {
        self.cityStore = cityStore
    }

    var menuBarTitle: String {
        if let temperature = menuBarTemperature {
            return "\(Int(temperature.rounded()))°"
        }
        return "Météo"
    }

    @MainActor
    func refresh() async {
        guard let city = cityStore.selectedCity else {
            message = "Aucune ville configurée. Ouvrez les réglages (engrenage) pour ajouter votre ville de résidence."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let forecast = try await client.forecast(lat: city.lat, lon: city.lon)
            daily = Array((forecast.dailyForecast ?? []).prefix(7))
            current = Self.currentHour(in: forecast.forecast ?? [])
            observation = try? await client.observation(lat: city.lat, lon: city.lon)

            if let home = cityStore.defaultCity, home.id != city.id {
                await refreshMenuBar(city: home)
            } else {
                updateMenuBar(city: city, forecast: forecast, observation: observation)
            }

            lastUpdate = Date()
            message = nil
        } catch {
            if let localized = error as? LocalizedError {
                message = localized.errorDescription ?? error.localizedDescription
            } else {
                message = error.localizedDescription
            }
        }
    }

    private func refreshMenuBar(city: City) async {
        guard let forecast = try? await client.forecast(lat: city.lat, lon: city.lon) else { return }
        let observation = try? await client.observation(lat: city.lat, lon: city.lon)
        await MainActor.run {
            updateMenuBar(city: city, forecast: forecast, observation: observation)
        }
    }

    private func updateMenuBar(city: City, forecast: ForecastResponse, observation: Observation?) {
        let hour = Self.currentHour(in: forecast.forecast ?? [])
        menuBarCityName = city.name
        menuBarTemperature = observation?.temperature
            ?? hour?.temperature
            ?? (forecast.dailyForecast ?? []).first?.tmax
        menuBarIcon = WeatherIcon.symbol(
            icon: observation?.weatherIcon ?? hour?.weatherIcon,
            desc: observation?.weatherDescription ?? hour?.weatherDesc
        )
    }

    static func currentHour(in hours: [HourlyForecast]) -> HourlyForecast? {
        let now = Date().timeIntervalSince1970
        return hours.min(by: { abs($0.dt - now) < abs($1.dt - now) })
    }
}
