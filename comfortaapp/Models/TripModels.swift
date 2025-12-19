import Foundation
import CoreLocation

// MARK: - Trip Data Model
public struct TripData {
    public let id: String
    public let pickupAddress: String
    public let destinationAddress: String
    public let pickupCoordinate: CLLocationCoordinate2D
    public let destinationCoordinate: CLLocationCoordinate2D
    public let estimatedFare: String
    public let estimatedDistance: String
    public let estimatedDuration: String
    public let passengerName: String
    public let requestTime: Date
    
    public init(
        pickupAddress: String,
        destinationAddress: String,
        pickupCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D,
        estimatedFare: String,
        estimatedDistance: String,
        estimatedDuration: String,
        passengerName: String
    ) {
        self.id = UUID().uuidString
        self.pickupAddress = pickupAddress
        self.destinationAddress = destinationAddress
        self.pickupCoordinate = pickupCoordinate
        self.destinationCoordinate = destinationCoordinate
        self.estimatedFare = estimatedFare
        self.estimatedDistance = estimatedDistance
        self.estimatedDuration = estimatedDuration
        self.passengerName = passengerName
        self.requestTime = Date()
    }
}

// MARK: - Enhanced Trip Status
public enum RideStatus: String, CaseIterable {
    case requested = "Solicitado"
    case driverAssigned = "Conductor asignado"
    case driverEnRoute = "Conductor en camino"
    case driverArrived = "Conductor ha llegado"
    case inProgress = "Viaje en curso"
    case completed = "Viaje completado"
    case cancelled = "Cancelado"
    
    public var icon: String {
        switch self {
        case .requested:
            return "clock.fill"
        case .driverAssigned:
            return "person.fill"
        case .driverEnRoute:
            return "car.fill"
        case .driverArrived:
            return "location.fill"
        case .inProgress:
            return "arrow.right.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .requested:
            return "orange"
        case .driverAssigned, .driverEnRoute:
            return "blue"
        case .driverArrived:
            return "green"
        case .inProgress:
            return "purple"
        case .completed:
            return "green"
        case .cancelled:
            return "red"
        }
    }
}

// MARK: - Driver Model
public struct Driver {
    public let id: String
    public let name: String
    public let rating: Double
    public let vehicleModel: String
    public let vehiclePlate: String
    public let vehicleColor: String
    public let phoneNumber: String
    public let photoURL: String?
    public let currentLocation: CLLocationCoordinate2D
    public let estimatedArrival: TimeInterval
    
    public init(
        id: String,
        name: String,
        rating: Double,
        vehicleModel: String,
        vehiclePlate: String,
        vehicleColor: String,
        phoneNumber: String,
        photoURL: String? = nil,
        currentLocation: CLLocationCoordinate2D,
        estimatedArrival: TimeInterval
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.vehicleModel = vehicleModel
        self.vehiclePlate = vehiclePlate
        self.vehicleColor = vehicleColor
        self.phoneNumber = phoneNumber
        self.photoURL = photoURL
        self.currentLocation = currentLocation
        self.estimatedArrival = estimatedArrival
    }
}

// MARK: - Trip Update Model
public struct TripUpdate {
    public let tripId: String
    public let status: RideStatus
    public let driver: Driver?
    public let message: String?
    public let timestamp: Date
    
    public init(
        tripId: String,
        status: RideStatus,
        driver: Driver? = nil,
        message: String? = nil,
        timestamp: Date = Date()
    ) {
        self.tripId = tripId
        self.status = status
        self.driver = driver
        self.message = message
        self.timestamp = timestamp
    }
}