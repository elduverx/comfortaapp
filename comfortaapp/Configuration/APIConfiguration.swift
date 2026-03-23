import Foundation
import UIKit

/// API Configuration for Comforta Mobile App
struct APIConfiguration {

    // MARK: - Base URLs

    static var baseURL: String {
        AppEnvironment.current.apiBaseURL
    }

    static var apiBasePath: String {
        return "/api"
    }

    static var adminBasePath: String {
        return "/api/admin"
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

        // Admin
        case adminAuth
        case adminTrips
        case adminTripDetail(id: String)
        case adminUsers
        case deviceTokens

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

            // Admin
            case .adminAuth:
                return "/auth"
            case .adminTrips:
                return "/viajes"
            case .adminTripDetail(let id):
                return "/viajes/\(id)"
            case .adminUsers:
                return "/users"
            case .deviceTokens:
                return "/device-tokens"
            }
        }

        private var basePath: String {
            switch self {
            case .adminAuth, .adminTrips, .adminTripDetail, .adminUsers:
                return APIConfiguration.adminBasePath
            default:
                return APIConfiguration.apiBasePath
            }
        }

        func url() -> URL {
            let urlString = APIConfiguration.baseURL + basePath + path
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
        AppEnvironment.current.enableLogging
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
        print("📍 Environment: \(AppEnvironment.current)")
        print("🌐 Base URL: \(baseURL)")
        print("🔗 API Base Path: \(apiBasePath)")
    }
}
