import Foundation
import AuthenticationServices
import Combine

/// Authentication Service using real API
class AuthServiceAPI: ObservableObject {
    static let shared = AuthServiceAPI()

    @Published var currentUser: APIUser?
    @Published var currentProfile: APIProfile?
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared

    private init() {
        // Check if we have tokens in keychain
        checkExistingSession()
    }

    // MARK: - Check Existing Session

    private func checkExistingSession() {
        if KeychainManager.shared.getAccessToken() != nil {
            // We have tokens, try to fetch profile
            Task {
                await fetchProfile()
            }
        }
    }

    // MARK: - Sign In with Apple

    func signIn(with credential: ASAuthorizationAppleIDCredential) {
        Task {
            await performSignIn(with: credential)
        }
    }

    @MainActor
    private func performSignIn(with credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        authenticationError = nil

        do {
            // Get identity token
            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                throw APIError.unknown
            }

            // Get authorization code (optional)
            let authorizationCode: String? = if let codeData = credential.authorizationCode {
                String(data: codeData, encoding: .utf8)
            } else {
                nil
            }

            // Build user info (only available on first sign-in)
            let userInfo: LoginAppleRequest.AppleUserInfo? = if let fullName = credential.fullName {
                LoginAppleRequest.AppleUserInfo(
                    name: LoginAppleRequest.AppleUserInfo.NameComponents(
                        firstName: fullName.givenName,
                        lastName: fullName.familyName
                    ),
                    email: credential.email
                )
            } else {
                nil
            }

            // Create request
            let request = LoginAppleRequest(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                user: userInfo
            )

            // Call API
            let response: LoginResponse = try await apiClient.request(
                endpoint: .loginApple,
                method: .post,
                body: request,
                requiresAuth: false
            )

            // Save tokens
            KeychainManager.shared.saveAccessToken(response.accessToken)
            KeychainManager.shared.saveRefreshToken(response.refreshToken)

            // Update state
            currentUser = response.user
            isAuthenticated = true
            authenticationError = nil

            await fetchProfile()

            // Track analytics
            AnalyticsService.shared.track(.signIn, metadata: [
                "method": "apple",
                "user_id": response.user.id
            ])

            print("✅ Sign in successful: \(response.user.id)")

        } catch let error as APIError {
            authenticationError = error.localizedDescription
            print("❌ Sign in failed: \(error)")
        } catch {
            authenticationError = "Error al iniciar sesión"
            print("❌ Sign in failed: \(error)")
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            await performSignOut()
        }
    }

    @MainActor
    private func performSignOut() async {
        do {
            // Get refresh token
            let refreshToken = KeychainManager.shared.getRefreshToken()
            let deviceToken = PushNotificationService.shared.deviceToken
                ?? UserDefaults.standard.string(forKey: "push_device_token")

            // Call logout API (best effort, don't fail if it errors)
            let request = LogoutRequest(
                refreshToken: refreshToken,
                deviceToken: deviceToken
            )

            try? await apiClient.requestNoResponse(
                endpoint: .logout,
                method: .post,
                body: request,
                requiresAuth: true
            )

            // Clear tokens
            KeychainManager.shared.clearAll()

            // Clear state
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
            authenticationError = nil

            // Track analytics
            AnalyticsService.shared.track(.signOut)

            print("✅ Sign out successful")

        } catch {
            print("⚠️ Sign out error (continuing anyway): \(error)")

            // Clear local state even if API call failed
            KeychainManager.shared.clearAll()
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
        }
    }

    // MARK: - Refresh Token

    func refreshToken() async throws {
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            throw APIError.unauthorized
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)

        let response: RefreshTokenResponse = try await apiClient.request(
            endpoint: .refreshToken,
            method: .post,
            body: request,
            requiresAuth: false
        )

        // Save new tokens
        KeychainManager.shared.saveAccessToken(response.accessToken)
        KeychainManager.shared.saveRefreshToken(response.refreshToken)

        print("✅ Token refreshed")
    }

    // MARK: - Fetch Profile

    @MainActor
    func fetchProfile() async {
        do {
            let response: ProfileResponse = try await apiClient.request(
                endpoint: .profile,
                method: .get,
                requiresAuth: true
            )

            currentProfile = response.profile
            currentUser = APIUser(
                id: response.profile.id,
                email: response.profile.email,
                name: response.profile.name,
                telefono: response.profile.telefono
            )
            isAuthenticated = true

            print("✅ Profile fetched: \(response.profile.id)")

        } catch APIError.unauthorized {
            // Token expired, try to refresh
            do {
                try await refreshToken()
                // Retry fetching profile
                await fetchProfile()
            } catch {
                // Refresh failed, sign out
                await performSignOut()
            }
        } catch {
            print("❌ Fetch profile failed: \(error)")
            // Don't sign out on network errors, just log
        }
    }

    // MARK: - Update Profile

    func updateProfile(name: String? = nil, telefono: String? = nil, email: String? = nil) async throws {
        let request = UpdateProfileRequest(
            name: name,
            telefono: telefono,
            email: email
        )

        let response: ProfileResponse = try await apiClient.request(
            endpoint: .profile,
            method: .patch,
            body: request,
            requiresAuth: true
        )

        await MainActor.run {
            currentProfile = response.profile
            currentUser = APIUser(
                id: response.profile.id,
                email: response.profile.email,
                name: response.profile.name,
                telefono: response.profile.telefono
            )
        }

        print("✅ Profile updated")
    }
}
