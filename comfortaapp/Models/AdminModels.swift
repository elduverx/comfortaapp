import SwiftUI

struct AdminStats {
    var totalActiveUsers: Int = 0
    var newUsersToday: Int = 0
    var tripsToday: Int = 0
    var tripGrowthPercent: Double = 0.0
    var totalRevenue: Double = 0.0
    var revenueToday: Double = 0.0
    var monthlyRevenue: Double = 0.0
    var monthlyGrowth: Double = 0.0
    var driversOnline: Int = 0
    var driverUtilization: Double = 0.0
    var platformCommission: Double = 0.0
    var commissionRate: Double = 0.0
}

struct RevenueData: Identifiable {
    let id = UUID()
    let date: Date
    let revenue: Double
}

struct TripStatusData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

struct PaymentMethodData: Identifiable {
    let id = UUID()
    let method: String
    let count: Int
}

struct SystemStatus {
    var uptimePercentage: Double = 0
    var averageResponseTime: Double = 0
    var incidentsToday: Int = 0
    var paymentsOperational: Bool = true
    var mapsOperational: Bool = true
    var realtimeOperational: Bool = true
    var lastSync: Date = Date()
}

struct AdminAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    var isResolved: Bool
}

enum AlertSeverity {
    case info
    case warning
    case critical

    var color: Color {
        switch self {
        case .info: return ComfortaDesign.Colors.info
        case .warning: return ComfortaDesign.Colors.warning
        case .critical: return ComfortaDesign.Colors.error
        }
    }
}

struct DriverPerformance: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
    let completedTrips: Int
    let earnings: Double
    let status: DriverStatus
}

enum DriverStatus {
    case online
    case onTrip
    case offline

    var label: String {
        switch self {
        case .online: return "Disponible"
        case .onTrip: return "En viaje"
        case .offline: return "Descansando"
        }
    }

    var color: Color {
        switch self {
        case .online: return ComfortaDesign.Colors.primaryGreen
        case .onTrip: return ComfortaDesign.Colors.warning
        case .offline: return ComfortaDesign.Colors.textSecondary
        }
    }
}

struct SupportTicket: Identifiable {
    let id = UUID()
    let reference: String
    let userName: String
    let subject: String
    let priority: TicketPriority
    var status: TicketStatus
    let createdAt: Date
}

enum TicketPriority {
    case low
    case medium
    case high

    var color: Color {
        switch self {
        case .low: return ComfortaDesign.Colors.info
        case .medium: return ComfortaDesign.Colors.warning
        case .high: return ComfortaDesign.Colors.error
        }
    }

    var title: String {
        switch self {
        case .low: return "Baja"
        case .medium: return "Media"
        case .high: return "Alta"
        }
    }
}

enum TicketStatus: CaseIterable {
    case open
    case inProgress
    case resolved

    var title: String {
        switch self {
        case .open: return "Abierto"
        case .inProgress: return "En curso"
        case .resolved: return "Resuelto"
        }
    }

    var color: Color {
        switch self {
        case .open: return ComfortaDesign.Colors.warning
        case .inProgress: return ComfortaDesign.Colors.info
        case .resolved: return ComfortaDesign.Colors.primaryGreen
        }
    }
}

struct AdminActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let timestamp: Date
    let icon: String
}

enum ActivityType {
    case userRegistered
    case userSuspended
    case userReactivated
    case tripCompleted
    case tripCancelled
    case driverVerified
    case paymentProcessed
    case refundProcessed
    case settingsChanged
}

enum UserFilter {
    case all
    case passengers
    case drivers
    case active
}

enum ReportPeriod {
    case daily
    case weekly
    case monthly
    case yearly
}

enum ExportFormat {
    case csv
    case json
    case pdf
}

struct AdminReport {
    let period: ReportPeriod
    let totalUsers: Int
    let activeUsers: Int
    let totalTrips: Int
    let completedTrips: Int
    let totalRevenue: Double
    let averageRating: Double
    let generatedAt: Date
}

struct PricingStructure: Codable {
    var baseFare: Double
    var perKilometerRate: Double
    var perMinuteRate: Double
    var minimumFare: Double
    var minimumFareForLongTrips: Double
    var minimumFareThreshold: Double
    var airportSurcharge: Double
    var commissionRate: Double
    var vehicleMultipliers: [String: Double]

    init(
        baseFare: Double = 0.0,
        perKilometerRate: Double = 1.50,
        perMinuteRate: Double = 0.0,
        minimumFare: Double = 7.50,
        minimumFareForLongTrips: Double = 15.00,
        minimumFareThreshold: Double = 10.0,
        airportSurcharge: Double = 8.00,
        commissionRate: Double = 15.0,
        vehicleMultipliers: [String: Double] = ["sedan": 1.0, "suv": 1.2, "van": 1.5, "luxury": 2.0]
    ) {
        self.baseFare = baseFare
        self.perKilometerRate = perKilometerRate
        self.perMinuteRate = perMinuteRate
        self.minimumFare = minimumFare
        self.minimumFareForLongTrips = minimumFareForLongTrips
        self.minimumFareThreshold = minimumFareThreshold
        self.airportSurcharge = airportSurcharge
        self.commissionRate = commissionRate
        self.vehicleMultipliers = vehicleMultipliers
    }
}
