import Foundation
import UserNotifications
import UIKit
import Combine

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var notificationSettings: UNNotificationSettings?
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if let error = error {
                        print("Notification permission error: \(error)")
                    }
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    promise(.success(granted))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationSettings = settings
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Trip Notifications
    
    func scheduleDriverAssignedNotification(for trip: Trip, driver: Driver) {
        let content = UNMutableNotificationContent()
        content.title = "Conductor Asignado"
        content.body = "\(driver.name) será tu conductor. \(driver.vehicleInfo.model) - \(driver.vehicleInfo.licensePlate)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "driver_assigned",
            "trip_id": trip.id,
            "driver_id": driver.id
        ]
        
        let request = UNNotificationRequest(
            identifier: "driver_assigned_\(trip.id)",
            content: content,
            trigger: nil
        )
        
        scheduleNotification(request)
    }
    
    func scheduleDriverEnRouteNotification(for trip: Trip, eta: String) {
        let content = UNMutableNotificationContent()
        content.title = "Conductor en Camino"
        content.body = "Tu conductor está en camino. Tiempo estimado de llegada: \(eta)"
        content.sound = .default
        content.userInfo = [
            "type": "driver_en_route",
            "trip_id": trip.id
        ]
        
        let request = UNNotificationRequest(
            identifier: "driver_en_route_\(trip.id)",
            content: content,
            trigger: nil
        )
        
        scheduleNotification(request)
    }
    
    func scheduleDriverArrivedNotification(for trip: Trip) {
        let content = UNMutableNotificationContent()
        content.title = "Conductor ha Llegado"
        content.body = "Tu conductor ha llegado al punto de recogida"
        content.sound = .default
        content.userInfo = [
            "type": "driver_arrived",
            "trip_id": trip.id
        ]
        
        let request = UNNotificationRequest(
            identifier: "driver_arrived_\(trip.id)",
            content: content,
            trigger: nil
        )
        
        scheduleNotification(request)
    }
    
    func scheduleTripStartedNotification(for trip: Trip) {
        let content = UNMutableNotificationContent()
        content.title = "Viaje Iniciado"
        content.body = "Tu viaje a \(trip.destinationLocation.address) ha comenzado"
        content.sound = .default
        content.userInfo = [
            "type": "trip_started",
            "trip_id": trip.id
        ]
        
        let request = UNNotificationRequest(
            identifier: "trip_started_\(trip.id)",
            content: content,
            trigger: nil
        )
        
        scheduleNotification(request)
    }
    
    func scheduleTripCompletedNotification(for trip: Trip) {
        let content = UNMutableNotificationContent()
        content.title = "Viaje Completado"
        content.body = "Has llegado a tu destino. ¡Esperamos que hayas disfrutado tu viaje!"
        content.sound = .default
        content.userInfo = [
            "type": "trip_completed",
            "trip_id": trip.id
        ]
        
        let request = UNNotificationRequest(
            identifier: "trip_completed_\(trip.id)",
            content: content,
            trigger: nil
        )
        
        scheduleNotification(request)
    }

    func scheduleTripCancelledNotification(for trip: Trip, reason: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Viaje Cancelado"
        content.body = reason ?? "Tu viaje fue cancelado. Puedes solicitar otro cuando quieras."
        content.sound = .default
        content.userInfo = [
            "type": "trip_cancelled",
            "trip_id": trip.id
        ]

        let request = UNNotificationRequest(
            identifier: "trip_cancelled_\(trip.id)",
            content: content,
            trigger: nil
        )

        scheduleNotification(request)
    }
    
    // MARK: - Promotional Notifications
    
    func schedulePromotionalNotification(title: String, message: String, delay: TimeInterval = 0) {
        guard UserManager.shared.currentUser?.preferences.notifications.promotions == true else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.userInfo = ["type": "promotional"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let request = UNNotificationRequest(
            identifier: "promo_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    // MARK: - Scheduled Trip Reminders
    
    func scheduleReminderForScheduledTrip(_ trip: Trip) {
        guard let scheduledDate = trip.scheduledAt else { return }
        
        // Schedule reminder 30 minutes before
        let reminderDate = scheduledDate.addingTimeInterval(-30 * 60)
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de Viaje"
        content.body = "Tu viaje programado para las \(DateFormatter.timeFormatter.string(from: scheduledDate)) está próximo"
        content.sound = .default
        content.userInfo = [
            "type": "trip_reminder",
            "trip_id": trip.id
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "trip_reminder_\(trip.id)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    // MARK: - Rating Reminders
    
    func scheduleRatingReminderNotification(for trip: Trip, delay: TimeInterval = 300) {
        let content = UNMutableNotificationContent()
        content.title = "¿Cómo fue tu viaje?"
        content.body = "Ayúdanos a mejorar calificando tu experiencia"
        content.sound = .default
        content.userInfo = [
            "type": "rating_reminder",
            "trip_id": trip.id
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "rating_reminder_\(trip.id)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    // MARK: - Helper Methods
    
    private func scheduleNotification(_ request: UNNotificationRequest) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotifications(for tripId: String) {
        let identifiers = [
            "driver_assigned_\(tripId)",
            "driver_en_route_\(tripId)",
            "driver_arrived_\(tripId)",
            "trip_started_\(tripId)",
            "trip_completed_\(tripId)",
            "trip_cancelled_\(tripId)",
            "trip_reminder_\(tripId)",
            "rating_reminder_\(tripId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String,
           let tripId = userInfo["trip_id"] as? String {
            handleNotificationResponse(type: type, tripId: tripId)
        }
        
        completionHandler()
    }
    
    private func handleNotificationResponse(type: String, tripId: String) {
        switch type {
        case "driver_assigned", "driver_en_route", "driver_arrived", "trip_started":
            // Navigate to active trip view
            NotificationCenter.default.post(
                name: .showActiveTrip,
                object: nil,
                userInfo: ["trip_id": tripId]
            )
            
        case "trip_completed", "rating_reminder":
            // Navigate to trip completion/rating view
            NotificationCenter.default.post(
                name: .showTripRating,
                object: nil,
                userInfo: ["trip_id": tripId]
            )
            
        case "trip_reminder", "trip_cancelled":
            // Navigate to trip details
            NotificationCenter.default.post(
                name: .showTripDetails,
                object: nil,
                userInfo: ["trip_id": tripId]
            )

        case "new_trip_request":
            // Navigate to admin trip details
            NotificationCenter.default.post(
                name: .showAdminTripDetails,
                object: nil,
                userInfo: ["trip_id": tripId]
            )
            
        default:
            break
        }
        
        AnalyticsService.shared.track(.notificationTapped, metadata: [
            "type": type,
            "trip_id": tripId
        ])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showActiveTrip = Notification.Name("showActiveTrip")
    static let showTripRating = Notification.Name("showTripRating")
    static let showTripDetails = Notification.Name("showTripDetails")
    static let showAdminTripDetails = Notification.Name("showAdminTripDetails")
    static let adminTripCompleted = Notification.Name("adminTripCompleted")
    static let requestNewTrip = Notification.Name("requestNewTrip")
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
}
