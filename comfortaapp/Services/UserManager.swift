import Foundation
import AuthenticationServices
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authenticationError: String?

    private let authService = AuthServiceAPI.shared
    private var cancellables = Set<AnyCancellable>()
    private var isAdminSession = false
    
    private init() {
        loadCurrentUser()
        bindAuthService()
    }
    
    // MARK: - Authentication
    
    func signIn(with credential: ASAuthorizationAppleIDCredential) {
        isAdminSession = false
        authService.signIn(with: credential)
    }
    
    func signOut() {
        isAdminSession = false
        authService.signOut()
        currentUser = nil
        isAuthenticated = false
        authenticationError = nil
        clearUserData()
        
        AnalyticsService.shared.track(.signOut)
    }
    
    func signInAsAdmin() {
        isAdminSession = true
        authService.signOut()
        let adminUser = User(
            id: "admin_user_001",
            firstName: "Administrador",
            lastName: "Comforta",
            email: "admin@comforta.app"
        )
        
        var admin = adminUser
        admin.userType = .admin
        admin.totalTrips = 250
        admin.totalSpent = 15500.0
        admin.loyaltyPoints = 5800
        admin.rating = 4.9
        admin.phoneNumber = "+34 600 123 456"
        admin.isActive = true
        admin.memberSince = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        admin.lastLoginDate = Date()
        
        currentUser = admin
        isAuthenticated = true
        authenticationError = nil
        saveCurrentUser()
        
        AnalyticsService.shared.track(.signIn, metadata: [
            "method": "admin_direct",
            "user_id": admin.id,
            "is_admin": "true"
        ])
    }
    
    func validateExistingSession(userId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userId) { state, error in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        if let user = self.loadUser(with: userId) {
                            self.currentUser = user
                            self.isAuthenticated = true
                        }
                        promise(.success(true))
                    default:
                        self.signOut()
                        promise(.success(false))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - User Profile Management
    
    func updateUserProfile(
        firstName: String? = nil,
        lastName: String? = nil,
        phoneNumber: String? = nil,
        preferences: UserPreferences? = nil
    ) {
        guard var user = currentUser else { return }
        
        if let firstName = firstName { user.firstName = firstName }
        if let lastName = lastName { user.lastName = lastName }
        if let phoneNumber = phoneNumber { user.phoneNumber = phoneNumber }
        if let preferences = preferences { user.preferences = preferences }
        
        currentUser = user
        saveCurrentUser()
        
        AnalyticsService.shared.track(.profileUpdated)
    }
    
    func updatePaymentMethod(_ paymentMethod: PaymentType) {
        guard var user = currentUser else { return }
        
        user.preferredPaymentMethod = paymentMethod
        currentUser = user
        saveCurrentUser()
        
        AnalyticsService.shared.track(.paymentMethodUpdated, metadata: [
            "method": paymentMethod.rawValue
        ])
    }
    
    func incrementTripCount() {
        guard var user = currentUser else { return }
        
        user.totalTrips += 1
        currentUser = user
        saveCurrentUser()

        PushNotificationService.shared.registerSavedTokenIfNeeded()
    }
    
    func addSpentAmount(_ amount: Double) {
        guard var user = currentUser else { return }
        
        user.totalSpent += amount
        user.loyaltyPoints += Int(amount * 10) // 10 points per euro
        currentUser = user
        saveCurrentUser()

        if isAuthenticated {
            PushNotificationService.shared.registerSavedTokenIfNeeded()
        }
    }
    
    func updateUserRating(_ newRating: Double, totalRatings: Int) {
        guard var user = currentUser else { return }
        
        // Calculate weighted average
        let currentTotal = user.rating * Double(max(1, user.totalTrips - 1))
        let newTotal = (currentTotal + newRating) / Double(user.totalTrips)
        user.rating = newTotal
        
        currentUser = user
        saveCurrentUser()
    }
    
    // MARK: - Driver Registration
    
    func registerAsDriver(
        licenseNumber: String,
        vehicleInfo: VehicleInfo
    ) -> AnyPublisher<Driver, Error> {
        guard let userId = currentUser?.id else {
            return Fail(error: UserError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        return Future<Driver, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let driverName = self.currentUser?.fullName ?? "Conductor"
                let driver = Driver(
                    userId: userId,
                    licenseNumber: licenseNumber,
                    name: driverName,
                    vehicleInfo: vehicleInfo
                )
                
                // Save driver info
                if let encoded = try? JSONEncoder().encode(driver) {
                    UserDefaults.standard.set(encoded, forKey: "driver_info_\(userId)")
                }
                
                // Update user type
                var user = self.currentUser!
                user.userType = .driver
                self.currentUser = user
                self.saveCurrentUser()
                
                AnalyticsService.shared.track(.driverRegistered)
                
                promise(.success(driver))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getDriverInfo() -> Driver? {
        guard let userId = currentUser?.id,
              let data = UserDefaults.standard.data(forKey: "driver_info_\(userId)"),
              let driver = try? JSONDecoder().decode(Driver.self, from: data) else {
            return nil
        }
        return driver
    }

    // MARK: - Auth Service Sync

    private func bindAuthService() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromAuthService()
            }
            .store(in: &cancellables)

        authService.$currentProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromAuthService()
            }
            .store(in: &cancellables)

        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromAuthService()
            }
            .store(in: &cancellables)

        authService.$authenticationError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.authenticationError = error
            }
            .store(in: &cancellables)
    }

    private func syncFromAuthService() {
        guard !isAdminSession else { return }

        isAuthenticated = authService.isAuthenticated

        guard let apiUser = authService.currentUser else {
            if !authService.isAuthenticated {
                currentUser = nil
            }
            return
        }

        var user = currentUser ?? User(
            id: apiUser.id,
            firstName: "",
            lastName: "",
            email: apiUser.email
        )

        let nameParts = (apiUser.name ?? "").split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? "Usuario"
        let lastName = nameParts.dropFirst().joined(separator: " ")

        user.firstName = firstName
        user.lastName = lastName
        user.email = apiUser.email
        user.phoneNumber = apiUser.telefono

        if let profile = authService.currentProfile {
            user.totalTrips = profile.stats.totalTrips
            user.totalSpent = profile.stats.totalSpent
            user.loyaltyPoints = Int(profile.stats.totalSpent * 10)
        }

        currentUser = user
        saveCurrentUser()
    }
    
    // MARK: - Persistence
    
    private func saveCurrentUser() {
        guard let user = currentUser else { return }
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "current_user")
            UserDefaults.standard.set(user.id, forKey: "user_id")
            UserDefaults.standard.set(true, forKey: "is_signed_in")
        }
    }
    
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func loadUser(with id: String) -> User? {
        if let data = UserDefaults.standard.data(forKey: "user_\(id)"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            return user
        }
        return nil
    }
    
    private func clearUserData() {
        UserDefaults.standard.removeObject(forKey: "current_user")
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.set(false, forKey: "is_signed_in")
        
        // Clear tab selection
        UserDefaults.standard.removeObject(forKey: "selected_tab")
        
        // Clear trip history
        UserDefaults.standard.removeObject(forKey: "trip_history")

        // Clear API trip cache
        UserDefaults.standard.removeObject(forKey: "trip_history_api_v1")
        UserDefaults.standard.removeObject(forKey: "active_trip_api_v1")

        // Clear active trip snapshot
        UserDefaults.standard.removeObject(forKey: "active_trip_snapshot_v1")

        // Clear admin cache
        UserDefaults.standard.removeObject(forKey: "admin_trip_snapshots_v1")
        UserDefaults.standard.removeObject(forKey: "admin_user_snapshots_v1")
    }
}

// MARK: - User Errors

enum UserError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case invalidUserData
    case registrationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuario no autenticado"
        case .userNotFound:
            return "Usuario no encontrado"
        case .invalidUserData:
            return "Datos de usuario inválidos"
        case .registrationFailed:
            return "Error en el registro"
        }
    }
}
