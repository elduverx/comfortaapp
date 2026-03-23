import Foundation
import UserNotifications
import Combine
import CoreLocation

/// Servicio profesional para manejar notificaciones push remotas
@MainActor
class PushNotificationService: ObservableObject {

    static let shared = PushNotificationService()

    // MARK: - Published Properties

    @Published var deviceToken: String?
    @Published var isRegistered = false
    @Published var lastNotification: PushNotificationData?

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadSavedToken()
    }

    // MARK: - Device Token Management

    func saveDeviceToken(_ token: String) {
        deviceToken = token
        isRegistered = true
        UserDefaults.standard.set(token, forKey: "push_device_token")
        UserDefaults.standard.set(Date(), forKey: "push_token_last_updated")

        print("✅ Device token saved: \(token)")

        // Enviar al servidor
        Task {
            await sendTokenToServer(token)
        }
    }

    func registerSavedTokenIfNeeded() {
        guard let token = deviceToken else { return }
        guard let prefs = UserManager.shared.currentUser?.preferences.notifications,
              prefs.pushNotifications else {
            return
        }

        Task {
            await sendTokenToServer(token)
        }
    }

    private func loadSavedToken() {
        if let token = UserDefaults.standard.string(forKey: "push_device_token") {
            deviceToken = token
            isRegistered = true
            print("📱 Loaded saved device token: \(token)")
        }
    }

    func clearDeviceToken() {
        deviceToken = nil
        isRegistered = false
        UserDefaults.standard.removeObject(forKey: "push_device_token")
        UserDefaults.standard.removeObject(forKey: "push_token_last_updated")

        print("🗑️ Device token cleared")
    }

    // MARK: - Server Communication

    private func sendTokenToServer(_ token: String) async {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("⚠️ No user ID - cannot send token to server")
            return
        }

        let request = DeviceTokenRequest(
            userId: userId,
            deviceToken: token,
            platform: "ios",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            deviceModel: await getDeviceModel(),
            osVersion: await getOSVersion(),
            timestamp: Date().timeIntervalSince1970
        )

        print("📤 Sending device token to server...")

        do {
            let requiresAuth = KeychainManager.shared.getAccessToken() != nil
            let response: DeviceTokenResponse = try await APIClient.shared.request(
                endpoint: .deviceTokens,
                method: .post,
                body: request,
                requiresAuth: requiresAuth
            )
            print("✅ Token registered successfully: \(response.success)")
        } catch {
            print("❌ Failed to register token: \(error)")
        }
    }

    func unregisterFromServer() async {
        guard let userId = UserManager.shared.currentUser?.id,
              let token = deviceToken else {
            return
        }

        print("📤 Unregistering device token from server...")

        // TODO: Si el backend soporta DELETE, agregarlo aquí.
        print("⚠️ Unregister endpoint not implemented for device tokens")
    }

    // MARK: - Notification Handling

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        print("📬 Processing remote notification...")

        let notification = parseNotification(userInfo)
        lastNotification = notification

        // Procesar según el tipo
        switch notification.type {
        case .driverAssigned:
            handleDriverAssigned(notification)

        case .driverEnRoute:
            handleDriverEnRoute(notification)

        case .driverArrived:
            handleDriverArrived(notification)

        case .tripStarted:
            handleTripStarted(notification)

        case .tripCompleted:
            handleTripCompleted(notification)

        case .promotional:
            handlePromotional(notification)

        case .tripReminder:
            handleTripReminder(notification)

        case .newTripRequest:
            handleNewTripRequest(notification)

        case .unknown:
            print("⚠️ Unknown notification type")
        }

        // Analytics
        AnalyticsService.shared.track(.pushNotificationReceived, metadata: [
            "type": notification.type.rawValue,
            "trip_id": notification.tripId ?? "none"
        ])
    }

    // MARK: - Notification Type Handlers

    private func handleDriverAssigned(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        NotificationCenter.default.post(
            name: .showActiveTrip,
            object: nil,
            userInfo: ["trip_id": tripId]
        )

        // Mostrar notificación local si la app está en foreground
        NotificationService.shared.scheduleDriverAssignedNotification(
            for: Trip.mock(id: tripId),
            driver: Driver.mock()
        )
    }

    private func handleDriverEnRoute(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        NotificationCenter.default.post(
            name: .showActiveTrip,
            object: nil,
            userInfo: ["trip_id": tripId]
        )
    }

    private func handleDriverArrived(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        NotificationCenter.default.post(
            name: .showActiveTrip,
            object: nil,
            userInfo: ["trip_id": tripId]
        )

        // Vibración fuerte para notificar llegada
        HapticManager.shared.notification(.success)
    }

    private func handleTripStarted(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        NotificationCenter.default.post(
            name: .showActiveTrip,
            object: nil,
            userInfo: ["trip_id": tripId]
        )
    }

    private func handleTripCompleted(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        NotificationCenter.default.post(
            name: .showTripRating,
            object: nil,
            userInfo: ["trip_id": tripId]
        )
    }

    private func handlePromotional(_ notification: PushNotificationData) {
        // Manejar notificaciones promocionales
        print("📢 Promotional notification: \(notification.title)")
    }

    private func handleTripReminder(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        NotificationCenter.default.post(
            name: .showTripDetails,
            object: nil,
            userInfo: ["trip_id": tripId]
        )
    }

    private func handleNewTripRequest(_ notification: PushNotificationData) {
        guard let tripId = notification.tripId else { return }

        // Notify admin service to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshAdminTrips"),
            object: nil,
            userInfo: ["trip_id": tripId]
        )

        // Play notification sound and haptic
        HapticManager.shared.notification(.warning)
    }

    // MARK: - Parsing

    private func parseNotification(_ userInfo: [AnyHashable: Any]) -> PushNotificationData {
        var title = ""
        var body = ""

        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                title = alert["title"] as? String ?? ""
                body = alert["body"] as? String ?? ""
            } else if let alertString = aps["alert"] as? String {
                title = alertString
            }
        }

        let typeString = userInfo["type"] as? String ?? "unknown"
        let tripId = userInfo["trip_id"] as? String
        let driverId = userInfo["driver_id"] as? String

        return PushNotificationData(
            title: title,
            body: body,
            type: NotificationType(rawValue: typeString) ?? .unknown,
            tripId: tripId,
            driverId: driverId,
            customData: userInfo
        )
    }

    // MARK: - Device Info

    private func getDeviceModel() async -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private func getOSVersion() async -> String {
        return "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
    }
}

// MARK: - Supporting Types

struct PushNotificationData {
    let title: String
    let body: String
    let type: NotificationType
    let tripId: String?
    let driverId: String?
    let customData: [AnyHashable: Any]
}

enum NotificationType: String {
    case driverAssigned = "driver_assigned"
    case driverEnRoute = "driver_en_route"
    case driverArrived = "driver_arrived"
    case tripStarted = "trip_started"
    case tripCompleted = "trip_completed"
    case promotional = "promotional"
    case tripReminder = "trip_reminder"
    case newTripRequest = "new_trip_request"
    case unknown
}

// MARK: - Mock Extensions (for testing)

extension Trip {
    static func mock(id: String) -> Trip {
        Trip(
            userId: "mock_user",
            pickupLocation: LocationInfo(
                address: "Mock Pickup",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            ),
            destinationLocation: LocationInfo(
                address: "Mock Destination",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            ),
            estimatedFare: 10.0,
            estimatedDistance: 5.0,
            estimatedDuration: 600,
            vehicleType: "Standard",
            paymentMethod: PaymentMethodInfo(type: .cash, displayName: "Cash", isDefault: true)
        )
    }
}

extension Driver {
    static func mock() -> Driver {
        Driver(
            userId: "mock_driver",
            licenseNumber: "ABC123",
            name: "Mock Driver",
            vehicleInfo: VehicleInfo(
                make: "Toyota",
                model: "Prius",
                year: 2023,
                color: "Blanco",
                licensePlate: "ABC-123",
                capacity: 4,
                vehicleType: .sedan
            )
        )
    }
}
