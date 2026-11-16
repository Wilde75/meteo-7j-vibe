import Foundation
import Security

enum KeychainStore {
    private static let service = "com.meteo7jours.app"
    private static let account = "meteofrance-api-token"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func saveToken(_ token: String) throws {
        let data = Data(token.utf8)
        let exists = SecItemCopyMatching(baseQuery as CFDictionary, nil) == errSecSuccess
        if exists {
            let status = SecItemUpdate(
                baseQuery as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
            guard status == errSecSuccess else { throw KeychainError.unknown(status) }
        } else {
            var query = baseQuery
            query[kSecValueData as String] = data
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else { throw KeychainError.unknown(status) }
        }
    }

    static func loadToken() throws -> String {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else { throw KeychainError.notFound }
        return token
    }

    static func deleteToken() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    enum KeychainError: LocalizedError {
        case notFound
        case unknown(OSStatus)

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "Aucun jeton enregistré dans le trousseau."
            case .unknown(let status):
                return "Erreur du trousseau (code \(status))."
            }
        }
    }
}
