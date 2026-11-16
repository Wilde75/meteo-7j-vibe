import Foundation

enum WeatherIcon {
    static func symbol(icon: String?, desc: String?) -> String {
        let text = (desc ?? "")
            .folding(options: [.diacriticInsensitive], locale: nil)
            .lowercased()
        let isNight = text.contains("nuit") || (text.isEmpty && (icon?.hasSuffix("n") ?? false))

        let base: String
        if text.contains("orage") {
            base = "cloud.bolt"
        } else if text.contains("grele") || text.contains("grêle") {
            base = "cloud.hail"
        } else if text.contains("neige") {
            base = "cloud.snow"
        } else if text.contains("verglas") {
            base = "cloud.sleet"
        } else if text.contains("brouillard") || text.contains("brume") {
            base = "cloud.fog"
        } else if text.contains("bruine") {
            base = "cloud.drizzle"
        } else if text.contains("averse") {
            base = "cloud.heavyrain"
        } else if text.contains("pluie") {
            base = "cloud.rain"
        } else if text.contains("ensoleille") || text.contains("degage") || text.contains("clair") {
            base = "sun.max"
        } else if text.contains("peu nuageux") {
            base = "cloud.sun"
        } else if text.contains("nuage") || text.contains("couvert") {
            base = "cloud"
        } else {
            switch icon {
            case "1": base = "sun.max"
            case "2", "3": base = "cloud.sun"
            case "4", "5": base = "cloud"
            case "6", "7", "8", "9": base = "cloud.rain"
            case "10", "11": base = "cloud.heavyrain"
            case "12", "13", "14": base = "cloud.snow"
            case "15", "16", "17": base = "cloud.bolt"
            case "18", "19": base = "cloud.fog"
            default: base = "cloud.sun"
            }
        }

        if isNight {
            switch base {
            case "sun.max": return "moon.stars"
            case "cloud.sun": return "cloud.moon"
            default: return base
            }
        }
        return base
    }
}
