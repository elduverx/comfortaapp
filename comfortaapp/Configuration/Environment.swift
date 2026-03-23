import Foundation

enum AppEnvironment: String {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        if let override = UserDefaults.standard.string(forKey: "app_environment_override"),
           let env = AppEnvironment(rawValue: override.lowercased()) {
            return env
        }

        if let plistValue = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String,
           let env = AppEnvironment(rawValue: plistValue.lowercased()) {
            return env
        }

        // For now, keep every build pointing to local development.
        return .development
    }

    var apiBaseURL: String {
        switch self {
        case .development:
            return "http://192.168.1.245:3000"
        case .staging:
            return "https://staging-api.comforta.app"
        case .production:
            return "https://api.comforta.app"
        }
    }

    var webSocketBaseURL: String {
        switch self {
        case .development:
            return "ws://192.168.1.245:3000"
        case .staging:
            return "wss://staging-api.comforta.app"
        case .production:
            return "wss://api.comforta.app"
        }
    }

    var enableLogging: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}
