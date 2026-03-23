import Foundation
import Combine
import UserNotifications
import UIKit

// MARK: - Admin Notification Manager

class AdminNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = AdminNotificationManager()

    @Published var isAuthorized = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )

            await MainActor.run {
                self.isAuthorized = granted
            }

            if granted {
                await setupNotificationCategories()
            }

            return granted
        } catch {
            print("❌ Error requesting notification authorization: \(error)")
            return false
        }
    }

    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Categories

    private func setupNotificationCategories() async {
        let tripCategory = createTripRequestCategory()
        let userCategory = createUserActionCategory()
        let systemCategory = createSystemAlertCategory()

        UNUserNotificationCenter.current().setNotificationCategories([
            tripCategory,
            userCategory,
            systemCategory
        ])

        print("✅ Notification categories configured")
    }

    private func createTripRequestCategory() -> UNNotificationCategory {
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_TRIP",
            title: "Aceptar",
            options: [.foreground]
        )

        let rejectAction = UNNotificationAction(
            identifier: "REJECT_TRIP",
            title: "Rechazar",
            options: [.destructive]
        )

        let viewAction = UNNotificationAction(
            identifier: "VIEW_TRIP",
            title: "Ver Detalles",
            options: [.foreground]
        )

        return UNNotificationCategory(
            identifier: "TRIP_REQUEST",
            actions: [acceptAction, rejectAction, viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    private func createUserActionCategory() -> UNNotificationCategory {
        let reviewAction = UNNotificationAction(
            identifier: "REVIEW_USER",
            title: "Revisar",
            options: [.foreground]
        )

        let approveAction = UNNotificationAction(
            identifier: "APPROVE_USER",
            title: "Aprobar",
            options: []
        )

        return UNNotificationCategory(
            identifier: "USER_ACTION",
            actions: [reviewAction, approveAction],
            intentIdentifiers: [],
            options: []
        )
    }

    private func createSystemAlertCategory() -> UNNotificationCategory {
        let acknowledgeAction = UNNotificationAction(
            identifier: "ACKNOWLEDGE_ALERT",
            title: "Entendido",
            options: []
        )

        let investigateAction = UNNotificationAction(
            identifier: "INVESTIGATE_ALERT",
            title: "Investigar",
            options: [.foreground]
        )

        return UNNotificationCategory(
            identifier: "SYSTEM_ALERT",
            actions: [acknowledgeAction, investigateAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    // MARK: - Send Notifications

    func sendTripRequestNotification(tripId: String, destination: String, price: Double) {
        let content = UNMutableNotificationContent()
        content.title = "🚕 Nueva Solicitud de Viaje"
        content.body = "Destino: \(destination)\nPrecio: €\(String(format: "%.2f", price))"
        content.sound = .defaultCritical
        content.categoryIdentifier = "TRIP_REQUEST"
        content.badge = NSNumber(value: 1)
        content.userInfo = [
            "type": "trip_request",
            "trip_id": tripId,
            "destination": destination,
            "price": price
        ]

        let request = UNNotificationRequest(
            identifier: "trip_\(tripId)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending trip notification: \(error)")
            } else {
                print("✅ Trip notification sent: \(tripId)")
            }
        }
    }

    func sendUserRegistrationNotification(userName: String, userId: String) {
        let content = UNMutableNotificationContent()
        content.title = "👤 Nuevo Usuario Registrado"
        content.body = "\(userName) se ha registrado en la plataforma"
        content.sound = .default
        content.categoryIdentifier = "USER_ACTION"
        content.userInfo = [
            "type": "user_registration",
            "user_id": userId,
            "user_name": userName
        ]

        let request = UNNotificationRequest(
            identifier: "user_\(userId)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendDriverVerificationNotification(driverName: String, driverId: String) {
        let content = UNMutableNotificationContent()
        content.title = "🚗 Conductor Pendiente de Verificación"
        content.body = "\(driverName) requiere verificación de documentos"
        content.sound = .default
        content.categoryIdentifier = "USER_ACTION"
        content.userInfo = [
            "type": "driver_verification",
            "driver_id": driverId,
            "driver_name": driverName
        ]

        let request = UNNotificationRequest(
            identifier: "driver_\(driverId)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendPaymentFailedNotification(tripId: String, amount: Double) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Pago Fallido"
        content.body = "El pago de €\(String(format: "%.2f", amount)) ha fallado para el viaje #\(tripId.prefix(8))"
        content.sound = .defaultCritical
        content.categoryIdentifier = "SYSTEM_ALERT"
        content.userInfo = [
            "type": "payment_failed",
            "trip_id": tripId,
            "amount": amount
        ]

        let request = UNNotificationRequest(
            identifier: "payment_failed_\(tripId)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendSystemAlertNotification(title: String, message: String, severity: AlertSeverity) {
        let content = UNMutableNotificationContent()
        content.title = "\(severity.emoji) \(title)"
        content.body = message
        content.sound = severity == .critical ? .defaultCritical : .default
        content.categoryIdentifier = "SYSTEM_ALERT"
        content.userInfo = [
            "type": "system_alert",
            "severity": severity.rawValue,
            "title": title
        ]

        let request = UNNotificationRequest(
            identifier: "alert_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendBulkNotification(title: String, body: String, category: String = "SYSTEM_ALERT") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("❌ Error updating badge count: \(error)")
            }
        }
    }

    func clearBadge() {
        updateBadgeCount(0)
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }

    func clearNotification(identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationAction(response)
        completionHandler()
    }

    // MARK: - Handle Actions

    private func handleNotificationAction(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        print("📲 Notification action: \(actionIdentifier)")

        switch actionIdentifier {
        case "ACCEPT_TRIP":
            if let tripId = userInfo["trip_id"] as? String {
                handleAcceptTrip(tripId)
            }

        case "REJECT_TRIP":
            if let tripId = userInfo["trip_id"] as? String {
                handleRejectTrip(tripId)
            }

        case "VIEW_TRIP":
            if let tripId = userInfo["trip_id"] as? String {
                handleViewTrip(tripId)
            }

        case "REVIEW_USER":
            if let userId = userInfo["user_id"] as? String {
                handleReviewUser(userId)
            }

        case "APPROVE_USER":
            if let userId = userInfo["user_id"] as? String {
                handleApproveUser(userId)
            }

        case "ACKNOWLEDGE_ALERT":
            print("✅ Alert acknowledged")

        case "INVESTIGATE_ALERT":
            handleInvestigateAlert()

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleDefaultAction(userInfo)

        default:
            break
        }
    }

    private func handleAcceptTrip(_ tripId: String) {
        Task {
            await AdminService.shared.acceptTrip(tripId)
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .showAdminTripDetails,
                    object: nil,
                    userInfo: ["trip_id": tripId]
                )
            }
        }
    }

    private func handleRejectTrip(_ tripId: String) {
        Task {
            await AdminService.shared.rejectTrip(tripId, reason: "Rechazado desde notificación")
        }
    }

    private func handleViewTrip(_ tripId: String) {
        NotificationCenter.default.post(
            name: .showAdminTripDetails,
            object: nil,
            userInfo: ["trip_id": tripId]
        )
    }

    private func handleReviewUser(_ userId: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("showUserDetails"),
            object: nil,
            userInfo: ["user_id": userId]
        )
    }

    private func handleApproveUser(_ userId: String) {
        print("✅ User approved: \(userId)")
        // Implement approval logic
    }

    private func handleInvestigateAlert() {
        NotificationCenter.default.post(
            name: NSNotification.Name("showSystemAlerts"),
            object: nil
        )
    }

    private func handleDefaultAction(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "trip_request":
            if let tripId = userInfo["trip_id"] as? String {
                handleViewTrip(tripId)
            }

        case "user_registration", "driver_verification":
            if let userId = userInfo["user_id"] as? String {
                handleReviewUser(userId)
            }

        case "system_alert":
            handleInvestigateAlert()

        default:
            break
        }
    }
}

// MARK: - Alert Severity Extension

extension AlertSeverity {
    var emoji: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .critical: return "🚨"
        }
    }

    var rawValue: String {
        switch self {
        case .info: return "info"
        case .warning: return "warning"
        case .critical: return "critical"
        }
    }
}

// MARK: - Notification Names Extension
