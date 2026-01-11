import SwiftUI
import CoreLocation

// MARK: - Trip Extensions
public extension Trip {
    var dateCreated: Date {
        createdAt
    }
}

// MARK: - TripStatus Extensions
public extension TripStatus {
    var color: Color {
        switch self {
        case .scheduled: return .blue
        case .requested: return .orange
        case .driverAssigned, .driverEnRoute: return .blue
        case .driverArrived: return ComfortaDesign.Colors.primaryGreen
        case .inProgress: return .purple
        case .completed: return ComfortaDesign.Colors.primaryGreen
        case .cancelled, .failed: return ComfortaDesign.Colors.error
        }
    }
}
