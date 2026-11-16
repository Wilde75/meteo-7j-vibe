import Foundation

enum APIError: LocalizedError {
    case missingToken
    case http(Int)
    case invalidResponse
    case decoding(DecodingError)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Jeton Météo-France absent : enregistrez-le dans Réglages → Connexion Météo-France."
        case .http(let code):
            return "L'API Météo-France a répondu avec le code HTTP \(code). Vérifiez votre jeton dans les réglages."
        case .invalidResponse:
            return "Réponse invalide de l'API Météo-France."
        case .decoding(let error):
            return "Impossible de lire la réponse de l'API Météo-France : \(error)"
        case .network(let error):
            return "Erreur réseau : \(error.localizedDescription)"
        }
    }
}

actor MeteoFranceClient {
    static let shared = MeteoFranceClient()

    private let baseURL = URL(string: "https://webservice.meteofrance.com")!
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        session = URLSession(configuration: configuration)
    }

    func searchPlaces(_ query: String) async throws -> [Place] {
        try await request("places", query: ["q": query])
    }

    func forecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        try await request(
            "forecast",
            query: ["lat": String(lat), "lon": String(lon), "lang": "fr"]
        )
    }

    func observation(lat: Double, lon: Double) async throws -> Observation {
        try await request(
            "v2/observation",
            query: ["lat": String(lat), "lon": String(lon), "lang": "fr"]
        )
    }

    private func request<T: Decodable>(_ path: String, query: [String: String]) async throws -> T {
        let token: String
        do {
            token = try KeychainStore.loadToken()
        } catch {
            throw APIError.missingToken
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        var items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        items.append(URLQueryItem(name: "token", value: token))
        components.queryItems = items
        guard let url = components.url else { throw APIError.invalidResponse }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: URLRequest(url: url))
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw APIError.decoding(decodingError)
        } catch {
            throw APIError.network(error)
        }
    }
}
