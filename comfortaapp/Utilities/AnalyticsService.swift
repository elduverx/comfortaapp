import Foundation

enum AnalyticsEvent: String {
    case viewHome
    case signIn
    case signOut
    case searchPickup
    case searchDestination
    case requestRide
    case confirmRide
    case cancelRide
    case viewPaywall
    case payConfirmed
    case payCancelled
    case swapLocations
    
    // User Management
    case profileUpdated
    case paymentMethodUpdated
    case driverRegistered
    case userSuspended
    case userReactivated
    
    // Trip Events
    case tripCreated
    case tripBooked
    case tripCancelled
    case tripStatusChanged
    case tripRated
    case tripCancelledByAdmin
    case tripAcceptedByAdmin
    case tripRejectedByAdmin
    case driverAssignedByAdmin
    case tripCompletedByAdmin
    
    // Payment Events
    case paymentInitiated
    case paymentCompleted
    case paymentFailed
    case refundProcessed
    
    // Tracking Events
    case trackingStarted
    case trackingStopped
    case emergencyTriggered
    case locationShared
    
    // Notification Events
    case notificationsEnabled
    case notificationsDenied
    case notificationTapped
    case pushNotificationRegistered
    case pushNotificationFailed
    case pushNotificationReceived
    
    // Admin Events
    case pricingUpdated
    case vehicleTypesUpdated
    case notificationSettingsUpdated
    case reportExported
    case securitySettingsUpdated
    case surgeActivated
    case alertResolved
    case supportTicketResolved
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}
    
    func track(_ event: AnalyticsEvent, metadata: [String: String] = [:]) {
        let payload = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " | ")
        print("📈 [Analytics] \(event.rawValue) \(payload)")
    }
}
