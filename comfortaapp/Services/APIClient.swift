import Foundation
import Security

/// HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case networkError(Error)
    case tokenExpired
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos"
        case .decodingError:
            return "Error al procesar la respuesta"
        case .serverError(let statusCode, let message):
            return message ?? "Error del servidor (\(statusCode))"
        case .unauthorized:
            return "No autorizado - Por favor inicia sesión nuevamente"
        case .networkError(let error):
            return "Error de conexión: \(error.localizedDescription)"
        case .tokenExpired:
            return "Sesión expirada"
        case .unknown:
            return "Error desconocido"
        }
    }
}

/// Main API Client
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.timeout
        configuration.timeoutIntervalForResource = APIConfiguration.timeout * 2
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": APIConfiguration.userAgent,
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]

        self.session = URLSession(configuration: configuration)

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601

        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601

        if APIConfiguration.enableLogging {
            print("🔧 APIClient initialized")
            print("🌐 Base URL: \(APIConfiguration.baseURL)")
        }
    }

    // MARK: - Request Building

    private func buildRequest(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) throws -> URLRequest {
        var url = endpoint.url()

        // Add query parameters
        if let queryItems = queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let urlWithQuery = components?.url else {
                throw APIError.invalidURL
            }
            url = urlWithQuery
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization header if required
        if requiresAuth {
            if let accessToken = KeychainManager.shared.getAccessToken() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            } else if APIConfiguration.enableLogging {
                print("⚠️ No access token found for authenticated request")
            }
        }

        // Add body
        if let body = body {
            request.httpBody = body
        }

        return request
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        do {
            // Encode body if provided
            let bodyData: Data? = if let body = body {
                try jsonEncoder.encode(body)
            } else {
                nil
            }

            // Build request
            var request = try buildRequest(
                endpoint: endpoint,
                method: method,
                body: bodyData,
                queryItems: queryItems,
                requiresAuth: requiresAuth
            )

            if APIConfiguration.enableLogging {
                print("📤 \(method.rawValue) \(request.url?.absoluteString ?? "")")
                if let body = bodyData, let jsonString = String(data: body, encoding: .utf8) {
                    print("📦 Body: \(jsonString)")
                }
            }

            // Execute request
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            if APIConfiguration.enableLogging {
                print("📥 Response: \(httpResponse.statusCode)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Data: \(jsonString)")
                }
            }

            // Handle response status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                do {
                    return try jsonDecoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }

            case 401:
                // Unauthorized - token expired
                throw APIError.unauthorized

            case 400...499:
                // Client error
                let errorMessage = try? jsonDecoder.decode(ErrorResponse.self, from: data)
                throw APIError.serverError(
                    statusCode: httpResponse.statusCode,
                    message: errorMessage?.error.message
                )

            case 500...599:
                // Server error
                throw APIError.serverError(
                    statusCode: httpResponse.statusCode,
                    message: "Error del servidor"
                )

            default:
                throw APIError.unknown
            }
        } catch {
            MonitoringService.shared.record(
                error: error,
                context: "\(method.rawValue) \(endpoint.path)"
            )
            throw error
        }
    }

    // MARK: - No Response Request (for DELETE, etc.)

    func requestNoResponse(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        struct EmptyResponse: Codable {}

        let _: EmptyResponse = try await request(
            endpoint: endpoint,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
    }
}

// MARK: - Error Response Model

struct ErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
        let code: String?
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()

    private let accessTokenKey = "comforta.accessToken"
    private let refreshTokenKey = "comforta.refreshToken"
    private let serviceName = "com.comforta.app"

    private init() {}

    // MARK: - Access Token

    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }

    func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }

    func deleteAccessToken() {
        delete(forKey: accessTokenKey)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }

    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }

    func deleteRefreshToken() {
        delete(forKey: refreshTokenKey)
    }

    // MARK: - Clear All

    func clearAll() {
        deleteAccessToken()
        deleteRefreshToken()
    }

    // MARK: - Private Helpers

    private func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess && APIConfiguration.enableLogging {
            print("⚠️ Keychain save error: \(status)")
        }
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
