import Foundation
import SwiftUI
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

// RideStatus is replaced by TripStatus for consistency

// Driver model is defined in UserModels.swift to avoid conflicts

// MARK: - Trip Update Model
public struct TripUpdate {
    public let tripId: String
    public let status: TripStatus
    public let driver: Driver?
    public let message: String?
    public let timestamp: Date
    
    public init(
        tripId: String,
        status: TripStatus,
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

// MARK: - Trip Booking Model
public struct Trip: Identifiable, Codable, Equatable {
    public let id: String
    public var userId: String
    public var driverId: String?
    public var status: TripStatus
    public var pickupLocation: LocationInfo
    public var destinationLocation: LocationInfo
    public var estimatedFare: Double
    public var actualFare: Double?
    public var estimatedDistance: Double
    public var actualDistance: Double?
    public var estimatedDuration: Double
    public var actualDuration: Double?
    public var vehicleType: String
    public var paymentMethod: PaymentMethodInfo
    public var specialRequests: [String]
    public var createdAt: Date
    public var scheduledAt: Date?
    public var pickedUpAt: Date?
    public var droppedOffAt: Date?
    public var cancelledAt: Date?
    public var driverRating: Double?
    public var passengerRating: Double?
    public var driverFeedback: String?
    public var passengerFeedback: String?
    public var route: RouteInfo?
    public var realTimeTracking: [LocationUpdate]
    
    public init(
        userId: String,
        pickupLocation: LocationInfo,
        destinationLocation: LocationInfo,
        estimatedFare: Double,
        estimatedDistance: Double,
        estimatedDuration: Double,
        vehicleType: String,
        paymentMethod: PaymentMethodInfo,
        specialRequests: [String] = [],
        scheduledAt: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.driverId = nil
        self.status = scheduledAt != nil ? .scheduled : .requested
        self.pickupLocation = pickupLocation
        self.destinationLocation = destinationLocation
        self.estimatedFare = estimatedFare
        self.actualFare = nil
        self.estimatedDistance = estimatedDistance
        self.actualDistance = nil
        self.estimatedDuration = estimatedDuration
        self.actualDuration = nil
        self.vehicleType = vehicleType
        self.paymentMethod = paymentMethod
        self.specialRequests = specialRequests
        self.createdAt = Date()
        self.scheduledAt = scheduledAt
        self.pickedUpAt = nil
        self.droppedOffAt = nil
        self.cancelledAt = nil
        self.driverRating = nil
        self.passengerRating = nil
        self.driverFeedback = nil
        self.passengerFeedback = nil
        self.route = nil
        self.realTimeTracking = []
    }
    
    // MARK: - Equatable
    public static func == (lhs: Trip, rhs: Trip) -> Bool {
        return lhs.id == rhs.id
    }
}

public extension Trip {
    var formattedDistance: String {
        let distance = actualDistance ?? estimatedDistance
        if distance < 1 {
            let meters = distance * 1000
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.1f km", distance)
    }
    
    var formattedDuration: String {
        let duration = actualDuration ?? estimatedDuration
        return TimeInterval(duration).formattedDuration
    }
    
    var formattedFare: String {
        let fare = actualFare ?? estimatedFare
        return String(format: "€%.2f", fare)
    }
}

public enum TripStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case requested = "requested"
    case driverAssigned = "driver_assigned"
    case driverEnRoute = "driver_en_route"
    case driverArrived = "driver_arrived"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case failed = "failed"
    
    public var displayName: String {
        switch self {
        case .scheduled: return "Programado"
        case .requested: return "Solicitado"
        case .driverAssigned: return "Conductor Asignado"
        case .driverEnRoute: return "Conductor en Camino"
        case .driverArrived: return "Conductor ha Llegado"
        case .inProgress: return "En Progreso"
        case .completed: return "Completado"
        case .cancelled: return "Cancelado"
        case .failed: return "Fallido"
        }
    }
    
    public var iconName: String {
        switch self {
        case .scheduled: return "calendar.circle.fill"
        case .requested: return "clock.fill"
        case .driverAssigned: return "person.circle.fill"
        case .driverEnRoute: return "car.fill"
        case .driverArrived: return "location.circle.fill"
        case .inProgress: return "arrow.right.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
    
    public var colorString: String {
        switch self {
        case .scheduled: return "blue"
        case .requested: return "orange"
        case .driverAssigned, .driverEnRoute: return "blue"
        case .driverArrived: return "green"
        case .inProgress: return "purple"
        case .completed: return "green"
        case .cancelled, .failed: return "red"
        }
    }
}

public struct LocationInfo: Codable, Hashable, Equatable {
    public let address: String
    public let coordinate: CoordinateInfo
    public let landmark: String?
    public let instructions: String?
    
    public init(address: String, coordinate: CLLocationCoordinate2D, landmark: String? = nil, instructions: String? = nil) {
        self.address = address
        self.coordinate = CoordinateInfo(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.landmark = landmark
        self.instructions = instructions
    }
    
    public var clLocationCoordinate: CLLocationCoordinate2D {
        coordinate.clLocationCoordinate
    }
    
    public static func == (lhs: LocationInfo, rhs: LocationInfo) -> Bool {
        lhs.address == rhs.address &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.landmark == rhs.landmark &&
        lhs.instructions == rhs.instructions
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(landmark)
        hasher.combine(instructions)
    }
}

public struct CoordinateInfo: Codable, Hashable, Equatable {
    public let latitude: Double
    public let longitude: Double
    
    public var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct PaymentMethodInfo: Codable, Equatable {
    public let type: PaymentType
    public let cardLast4: String?
    public let processorTransactionId: String?
    public let amount: Double?
    public let currency: String
    public let tip: Double?
    public let displayName: String
    public let isDefault: Bool
    
    public init(
        type: PaymentType,
        cardLast4: String? = nil,
        currency: String = "EUR",
        displayName: String? = nil,
        isDefault: Bool = false
    ) {
        self.type = type
        self.cardLast4 = cardLast4
        self.processorTransactionId = nil
        self.amount = nil
        self.currency = currency
        self.tip = nil
        self.displayName = displayName ?? type.displayName
        self.isDefault = isDefault
    }
}

public enum PaymentType: String, Codable, CaseIterable {
    case applePay = "apple_pay"
    case creditCard = "credit_card"
    case cash = "cash"
    
    public var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .creditCard: return "Tarjeta de Crédito"
        case .cash: return "Efectivo"
        }
    }

    public var iconName: String {
        switch self {
        case .applePay: return "applelogo"
        case .creditCard: return "creditcard.fill"
        case .cash: return "banknote.fill"
        }
    }
}

public typealias PaymentMethodType = PaymentType

public struct PaymentRecord: Identifiable, Codable {
    public let id: String
    public let tripId: String
    public let userId: String
    public let amount: Double
    public let method: PaymentType
    public let transactionId: String
    public let status: PaymentStatus
    public let processedAt: Date
    public let description: String?
    
    public init(tripId: String, userId: String, amount: Double, method: PaymentType, transactionId: String? = nil) {
        self.id = UUID().uuidString
        self.tripId = tripId
        self.userId = userId
        self.amount = amount
        self.method = method
        self.transactionId = transactionId ?? UUID().uuidString
        self.status = .completed
        self.processedAt = Date()
        self.description = nil
    }
}

public enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .processing: return "Procesando"
        case .completed: return "Completado"
        case .failed: return "Fallido"
        case .refunded: return "Reembolsado"
        }
    }
}

public struct RouteInfo: Codable {
    public let waypoints: [CoordinateInfo]
    public let distance: Double
    public let duration: Double
    public let polyline: String?
    
    public init(waypoints: [CLLocationCoordinate2D], distance: Double, duration: Double, polyline: String? = nil) {
        self.waypoints = waypoints.map { CoordinateInfo(latitude: $0.latitude, longitude: $0.longitude) }
        self.distance = distance
        self.duration = duration
        self.polyline = polyline
    }
}

public struct LocationUpdate: Codable, Identifiable {
    public let id: String
    public let tripId: String
    public let userId: String
    public let coordinate: CoordinateInfo
    public let heading: Double?
    public let speed: Double?
    public let accuracy: Double?
    public let timestamp: Date
    
    public init(tripId: String, userId: String, coordinate: CLLocationCoordinate2D, heading: Double? = nil, speed: Double? = nil, accuracy: Double? = nil) {
        self.id = UUID().uuidString
        self.tripId = tripId
        self.userId = userId
        self.coordinate = CoordinateInfo(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.heading = heading
        self.speed = speed
        self.accuracy = accuracy
        self.timestamp = Date()
    }
}
