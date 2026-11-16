import Foundation

final class CityStore: ObservableObject {
    static let shared = CityStore()

    @Published var cities: [City] = []
    @Published var selectedCityID: String?

    private let defaults = UserDefaults.standard
    private let citiesKey = "meteo7jours.cities"
    private let selectedKey = "meteo7jours.selectedCityID"

    init() {
        load()
    }

    var defaultCity: City? {
        cities.first(where: { $0.isDefault }) ?? cities.first
    }

    var selectedCity: City? {
        cities.first(where: { $0.id == selectedCityID }) ?? defaultCity
    }

    func load() {
        if let data = defaults.data(forKey: citiesKey),
           let decoded = try? JSONDecoder().decode([City].self, from: data) {
            cities = decoded
        }
        selectedCityID = defaults.string(forKey: selectedKey) ?? defaultCity?.id
    }

    func save() {
        if let data = try? JSONEncoder().encode(cities) {
            defaults.set(data, forKey: citiesKey)
        }
        defaults.set(selectedCityID, forKey: selectedKey)
    }

    func addCity(from place: Place) {
        guard !cities.contains(where: { $0.id == place.id }) else { return }
        var city = City(place: place)
        if cities.isEmpty {
            city.isDefault = true
        }
        cities.append(city)
        if selectedCityID == nil {
            selectedCityID = city.id
        }
        save()
    }

    func remove(_ city: City) {
        let wasDefault = city.isDefault
        cities.removeAll { $0.id == city.id }
        if wasDefault, let index = cities.indices.first {
            cities[index].isDefault = true
        }
        if selectedCityID == city.id {
            selectedCityID = defaultCity?.id
        }
        save()
    }

    func setDefault(_ city: City) {
        for index in cities.indices {
            cities[index].isDefault = cities[index].id == city.id
        }
        save()
    }

    func select(_ city: City) {
        selectedCityID = city.id
        save()
    }
}
