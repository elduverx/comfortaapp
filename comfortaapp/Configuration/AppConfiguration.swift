import Foundation
import CoreLocation

// MARK: - App Configuration

struct AppConfiguration {
    
    // MARK: - Location Configuration
    struct Location {
        static let defaultRegionLatitude: Double = 40.4168 // Madrid
        static let defaultRegionLongitude: Double = -3.7038
        static let defaultRegionSpan: Double = 0.08
        static let minimumSearchQueryLength: Int = 2
        static let searchDebounceDelay: TimeInterval = 0.3
        static let locationUpdateDistanceFilter: Double = 10.0
        static let requestLocationTimeout: TimeInterval = 10.0
    }
    
    // MARK: - Trip Configuration
    struct Trip {
        static let baseRatePerKm: Double = 1.50
        static let longDistanceRatePerKm: Double = 1.10
        static let longDistanceThreshold: Double = 100.0 // km
        static let averageCitySpeedKmh: Double = 50.0
        static let currencyCode: String = "EUR"
        static let localeIdentifier: String = "es_ES"
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: TimeInterval = 0.3
        static let fastAnimationDuration: TimeInterval = 0.2
        static let maxSearchSuggestions: Int = 5
        static let mapAnnotationSize: CGFloat = 32
        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 12
        static let shadowOpacity: Double = 0.08
    }
    
    // MARK: - Performance Configuration
    struct Performance {
        static let maxConcurrentSearchRequests: Int = 3
        static let cacheRetentionTime: TimeInterval = 300 // 5 minutes
        static let backgroundTaskTimeout: TimeInterval = 30
        static let maxRetryAttempts: Int = 3
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let locationPermissionDenied = "Los permisos de ubicación están desactivados. Ve a Ajustes para habilitarlos."
        static let locationNotAvailable = "No se pudo obtener la ubicación actual."
        static let networkError = "Error de conexión. Verifica tu conexión a internet."
        static let searchNoResults = "No se encontraron resultados para tu búsqueda."
        static let tripCalculationFailed = "Error al calcular el viaje. Inténtalo de nuevo."
        static let unknownError = "Ha ocurrido un error inesperado."
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableRealTimeTracking = true
        static let enableOfflineMode = false
        static let enableAnalytics = false
        static let enableBiometrics = false
        static let enableNotifications = true
        static let enableDarkMode = true
    }
}
