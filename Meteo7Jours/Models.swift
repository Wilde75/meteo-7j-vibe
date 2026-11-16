import Foundation

struct FlexibleString: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Valeur non textuelle")
            )
        }
    }
}

struct Weather: Decodable {
    let icon: String?
    let desc: String?

    enum CodingKeys: String, CodingKey {
        case icon, desc
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        icon = try container.decodeIfPresent(FlexibleString.self, forKey: .icon)?.value
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
    }
}

struct Place: Decodable, Identifiable, Hashable {
    let insee: String?
    let name: String
    let lat: Double
    let lon: Double
    let country: String?
    let admin: String?
    let admin2: String?
    let postCode: String?

    var id: String { insee ?? String(format: "%.5f,%.5f", lat, lon) }

    enum CodingKeys: String, CodingKey {
        case insee, name, lat, lon, country, admin, admin2
        case postCode = "postCode"
    }

    var subtitle: String {
        var parts: [String] = []
        if let admin { parts.append(admin) }
        if let admin2 { parts.append("(\(admin2))") }
        if let postCode { parts.append(postCode) }
        return parts.joined(separator: " ")
    }
}

struct City: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var detail: String
    var lat: Double
    var lon: Double
    var insee: String?
    var isDefault: Bool

    init(place: Place) {
        id = place.id
        name = place.name
        detail = place.subtitle
        lat = place.lat
        lon = place.lon
        insee = place.insee
        isDefault = false
    }
}

struct Position: Decodable {
    let lat: Double?
    let lon: Double?
    let timezone: String?
}

struct TempPoint: Decodable {
    let value: Double?
    let min: Double?
    let max: Double?
    let windchill: Double?
}

struct RainSnow: Decodable {
    let hour1: Double?

    enum CodingKeys: String, CodingKey {
        case hour1 = "1h"
    }
}

struct Wind: Decodable {
    let speed: Double?
    let direction: Double?
    let icon: String?
}

struct DailyForecast: Decodable, Identifiable {
    let day: Int?
    let datetime: String?
    var tmin: Double?
    var tmax: Double?
    var weatherIcon: String?
    var weatherDesc: String?
    var rainProbability: Int?
    var rainAmount: Double?
    var wind10m: Int?

    var id: Int { day ?? 0 }

    enum CodingKeys: String, CodingKey {
        case day, datetime, T, weather12H, weather, probarain, rr10, wind10m
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decodeIfPresent(Int.self, forKey: .day)
        datetime = try container.decodeIfPresent(String.self, forKey: .datetime)
        rainProbability = try container.decodeIfPresent(Int.self, forKey: .probarain)
        rainAmount = try container.decodeIfPresent(Double.self, forKey: .rr10)
        wind10m = try container.decodeIfPresent(Int.self, forKey: .wind10m)
        if let temp = try? container.decode(TempPoint.self, forKey: .T) {
            tmin = temp.min ?? temp.value
            tmax = temp.max ?? temp.value
        }
        let weather = (try? container.decode(Weather.self, forKey: .weather12H))
            ?? (try? container.decode(Weather.self, forKey: .weather))
        weatherIcon = weather?.icon
        weatherDesc = weather?.desc
    }
}

struct HourlyForecast: Decodable, Identifiable {
    let dt: TimeInterval
    var temperature: Double?
    var windChill: Double?
    var weatherIcon: String?
    var weatherDesc: String?
    var rain1h: Double?
    var snow1h: Double?
    var clouds: Double?
    var windSpeed: Double?
    var windDirection: Double?

    var id: TimeInterval { dt }

    enum CodingKeys: String, CodingKey {
        case dt, T, weather, rain, snow, clouds, wind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dt = try container.decode(TimeInterval.self, forKey: .dt)
        if let temp = try? container.decode(TempPoint.self, forKey: .T) {
            temperature = temp.value
            windChill = temp.windchill
        }
        if let weather = try? container.decode(Weather.self, forKey: .weather) {
            weatherIcon = weather.icon
            weatherDesc = weather.desc
        }
        if let rain = try? container.decode(RainSnow.self, forKey: .rain) {
            rain1h = rain.hour1
        }
        if let snow = try? container.decode(RainSnow.self, forKey: .snow) {
            snow1h = snow.hour1
        }
        clouds = try container.decodeIfPresent(Double.self, forKey: .clouds)
        if let wind = try? container.decode(Wind.self, forKey: .wind) {
            windSpeed = wind.speed
            windDirection = wind.direction
        }
    }
}

struct ForecastResponse: Decodable {
    let position: Position?
    let updatedOn: TimeInterval?
    let dailyForecast: [DailyForecast]?
    let forecast: [HourlyForecast]?

    enum CodingKeys: String, CodingKey {
        case position
        case updatedOn = "updated_on"
        case dailyForecast = "daily_forecast"
        case forecast
    }
}

struct Observation: Decodable {
    let timezone: String?
    let time: String?
    let temperature: Double?
    let windSpeed: Double?
    let windDirection: Double?
    let windIcon: String?
    let weatherIcon: String?
    let weatherDescription: String?

    enum CodingKeys: String, CodingKey {
        case timezone, time, temperature
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case windIcon = "wind_icon"
        case weatherIcon = "weather_icon"
        case weatherDescription = "weather_description"
    }
}
