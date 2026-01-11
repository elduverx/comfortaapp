import Foundation
import UIKit

/// API Configuration for Comforta Mobile App
struct APIConfiguration {

    // MARK: - Environment

    enum Environment {
        case development
        case staging
        case production

        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
    }

    // MARK: - Base URLs

    static var baseURL: String {
        switch Environment.current {
        case .development:
            // Local development - Update this to your actual dev server or use production
            return "https://comforta.es"
        case .staging:
            return "https://staging.comforta.es"
        case .production:
            return "https://comforta.es"
        }
    }

    static var apiBasePath: String {
        return "/api/mobile"
    }

    static var fullAPIURL: String {
        return baseURL + apiBasePath
    }

    // MARK: - Endpoints

    enum Endpoint {
        // Auth
        case loginApple
        case refreshToken
        case logout

        // Trips
        case trips
        case tripDetail(id: String)
        case tripStatus(id: String)

        // Pricing
        case calculatePricing

        // Favorites
        case favorites
        case favoriteDetail(id: String)

        // Profile
        case profile

        var path: String {
            switch self {
            // Auth
            case .loginApple:
                return "/auth/login/apple"
            case .refreshToken:
                return "/auth/refresh"
            case .logout:
                return "/auth/logout"

            // Trips
            case .trips:
                return "/trips"
            case .tripDetail(let id):
                return "/trips/\(id)"
            case .tripStatus(let id):
                return "/trips/\(id)/status"

            // Pricing
            case .calculatePricing:
                return "/pricing/calculate"

            // Favorites
            case .favorites:
                return "/favorites"
            case .favoriteDetail(let id):
                return "/favorites/\(id)"

            // Profile
            case .profile:
                return "/profile"
            }
        }

        func url() -> URL {
            let urlString = APIConfiguration.fullAPIURL + path
            guard let url = URL(string: urlString) else {
                fatalError("Invalid URL: \(urlString)")
            }
            return url
        }
    }

    // MARK: - Network Configuration

    /// Default timeout for API requests (in seconds)
    static let timeout: TimeInterval = 30

    /// Maximum number of retry attempts for failed requests
    static let maxRetries: Int = 3

    /// Delay between retry attempts (in seconds)
    static let retryDelay: TimeInterval = 1.0

    // MARK: - Logging

    static var enableLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Feature Flags

    struct Features {
        /// Enable automatic token refresh
        static let autoRefreshTokens = true

        /// Enable request caching
        static let enableCaching = true

        /// Cache duration (in seconds)
        static let cacheDuration: TimeInterval = 300 // 5 minutes
    }

    // MARK: - App Information

    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var userAgent: String {
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        return "Comforta-iOS/\(appVersion) (\(buildNumber)) iOS/\(systemVersion) \(deviceModel)"
    }
}

// MARK: - Validation

extension APIConfiguration {
    static func validateConfiguration() {
        assert(!baseURL.isEmpty, "Base URL must not be empty")
        assert(URL(string: baseURL) != nil, "Base URL must be valid")
        print("✅ API Configuration validated")
        print("📍 Environment: \(Environment.current)")
        print("🌐 Base URL: \(baseURL)")
        print("🔗 API Base Path: \(apiBasePath)")
    }
}
