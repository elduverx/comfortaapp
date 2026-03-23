import UIKit
import UserNotifications

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configurar el delegate de notificaciones
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        // Nota: Las notificaciones push remotas requieren configuración de entitlements
        // Las notificaciones locales funcionarán sin esto
        // registerForPushNotifications(application: application)
        registerForRemoteNotificationsIfAuthorized(application: application)

        return true
    }

    // MARK: - Push Notifications Registration

    private func registerForPushNotifications(application: UIApplication) {
        // Solicitar permisos de notificaciones
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("📱 Permission granted: \(granted)")

            if let error = error {
                print("❌ Error requesting notification permissions: \(error.localizedDescription)")
                return
            }

            if granted {
                DispatchQueue.main.async {
                    // Registrarse para notificaciones remotas
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    private func registerForRemoteNotificationsIfAuthorized(application: UIApplication) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Device Token Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()

        print("✅ Device Token: \(token)")

        PushNotificationService.shared.saveDeviceToken(token)

        // Analytics
        AnalyticsService.shared.track(.pushNotificationRegistered, metadata: [
            "token_length": "\(token.count)"
        ])
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")

        PushNotificationService.shared.clearDeviceToken()

        // Analytics
        AnalyticsService.shared.track(.pushNotificationFailed, metadata: [
            "error": error.localizedDescription
        ])
    }

    // MARK: - Receiving Push Notifications

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📬 Received remote notification: \(userInfo)")
        PushNotificationService.shared.handleRemoteNotification(userInfo)

        completionHandler(.newData)
    }

    // MARK: - Helper Methods
}
