import Foundation
import CoreLocation

struct User: Identifiable, Codable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String?
    var phoneNumber: String?
    var profileImageURL: String?
    var dateCreated: Date
    var lastLoginDate: Date
    var memberSince: Date
    var userType: UserType
    var preferredPaymentMethod: PaymentType
    var isActive: Bool
    var rating: Double
    var totalTrips: Int
    var totalSpent: Double
    var loyaltyPoints: Int
    var preferences: UserPreferences
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(id: String, firstName: String, lastName: String, email: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = nil
        self.profileImageURL = nil
        self.dateCreated = Date()
        self.lastLoginDate = Date()
        self.memberSince = Date()
        self.userType = .passenger
        self.preferredPaymentMethod = .cash
        self.isActive = true
        self.rating = 5.0
        self.totalTrips = 0
        self.totalSpent = 0.0
        self.loyaltyPoints = 0
        self.preferences = UserPreferences()
    }
}

enum UserType: String, Codable, CaseIterable {
    case passenger = "passenger"
    case driver = "driver"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .passenger: return "Pasajero"
        case .driver: return "Conductor"
        case .admin: return "Administrador"
        }
    }
}

struct UserPreferences: Codable {
    var notifications: NotificationPreferences
    var accessibility: AccessibilityPreferences
    var privacy: PrivacyPreferences
    var language: String
    var currency: String
    
    init() {
        self.notifications = NotificationPreferences()
        self.accessibility = AccessibilityPreferences()
        self.privacy = PrivacyPreferences()
        self.language = "es"
        self.currency = "EUR"
    }
}

struct NotificationPreferences: Codable {
    var pushNotifications: Bool
    var emailNotifications: Bool
    var smsNotifications: Bool
    var rideUpdates: Bool
    var promotions: Bool
    
    init() {
        self.pushNotifications = true
        self.emailNotifications = true
        self.smsNotifications = false
        self.rideUpdates = true
        self.promotions = false
    }
}

struct AccessibilityPreferences: Codable {
    var voiceOver: Bool
    var largeText: Bool
    var highContrast: Bool
    var reducedMotion: Bool
    
    init() {
        self.voiceOver = false
        self.largeText = false
        self.highContrast = false
        self.reducedMotion = false
    }
}

struct PrivacyPreferences: Codable {
    var shareLocationData: Bool
    var shareUsageData: Bool
    var allowMarketing: Bool
    
    init() {
        self.shareLocationData = true
        self.shareUsageData = false
        self.allowMarketing = false
    }
}

public struct Driver: Identifiable, Codable {
    public let id: String
    public var userId: String
    public var licenseNumber: String
    public var name: String
    public var vehicleInfo: VehicleInfo
    public var isActive: Bool
    public var isOnline: Bool
    public var currentLocation: LocationData?
    public var rating: Double
    public var totalTrips: Int
    public var totalEarnings: Double
    public var documentVerification: DocumentVerification
    public var phoneNumber: String?
    public var estimatedArrival: TimeInterval
    
    public init(userId: String, licenseNumber: String, name: String, vehicleInfo: VehicleInfo) {
        self.id = UUID().uuidString
        self.userId = userId
        self.licenseNumber = licenseNumber
        self.name = name
        self.vehicleInfo = vehicleInfo
        self.isActive = false
        self.isOnline = false
        self.currentLocation = nil
        self.rating = 5.0
        self.totalTrips = 0
        self.totalEarnings = 0.0
        self.documentVerification = DocumentVerification()
        self.phoneNumber = nil
        self.estimatedArrival = 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case licenseNumber
        case name
        case vehicleInfo
        case isActive
        case isOnline
        case currentLocation
        case rating
        case totalTrips
        case totalEarnings
        case documentVerification
        case phoneNumber
        case estimatedArrival
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        licenseNumber = try container.decode(String.self, forKey: .licenseNumber)
        name = try container.decode(String.self, forKey: .name)
        vehicleInfo = try container.decode(VehicleInfo.self, forKey: .vehicleInfo)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        currentLocation = try container.decodeIfPresent(LocationData.self, forKey: .currentLocation)
        rating = try container.decode(Double.self, forKey: .rating)
        totalTrips = try container.decode(Int.self, forKey: .totalTrips)
        totalEarnings = try container.decode(Double.self, forKey: .totalEarnings)
        documentVerification = try container.decode(DocumentVerification.self, forKey: .documentVerification)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        estimatedArrival = try container.decodeIfPresent(TimeInterval.self, forKey: .estimatedArrival) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(licenseNumber, forKey: .licenseNumber)
        try container.encode(name, forKey: .name)
        try container.encode(vehicleInfo, forKey: .vehicleInfo)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encodeIfPresent(currentLocation, forKey: .currentLocation)
        try container.encode(rating, forKey: .rating)
        try container.encode(totalTrips, forKey: .totalTrips)
        try container.encode(totalEarnings, forKey: .totalEarnings)
        try container.encode(documentVerification, forKey: .documentVerification)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encode(estimatedArrival, forKey: .estimatedArrival)
    }
}

extension Driver {
    var vehicleModel: String { vehicleInfo.displayName }
    var vehicleColor: String { vehicleInfo.color }
    var vehiclePlate: String { vehicleInfo.licensePlate }
    var currentCoordinate: CLLocationCoordinate2D? { currentLocation?.coordinate.clLocationCoordinate }
}

public struct VehicleInfo: Codable {
    var make: String
    var model: String
    var year: Int
    var color: String
    var licensePlate: String
    var capacity: Int
    var vehicleType: VehicleType
    
    var displayName: String {
        "\(make) \(model) (\(year))"
    }
}

enum VehicleType: String, Codable, CaseIterable {
    case sedan = "sedan"
    case suv = "suv"
    case van = "van"
    case luxury = "luxury"
    
    var displayName: String {
        switch self {
        case .sedan: return "Sedán"
        case .suv: return "SUV"
        case .van: return "Furgoneta"
        case .luxury: return "Lujo"
        }
    }
    
    var baseRate: Double {
        switch self {
        case .sedan: return 1.0
        case .suv: return 1.2
        case .van: return 1.5
        case .luxury: return 2.0
        }
    }
}

public struct DocumentVerification: Codable {
    var licenseVerified: Bool
    var insuranceVerified: Bool
    var backgroundCheckVerified: Bool
    var vehicleInspectionVerified: Bool
    var lastVerificationDate: Date?
    
    init() {
        self.licenseVerified = false
        self.insuranceVerified = false
        self.backgroundCheckVerified = false
        self.vehicleInspectionVerified = false
        self.lastVerificationDate = nil
    }
    
    var isFullyVerified: Bool {
        licenseVerified && insuranceVerified && backgroundCheckVerified && vehicleInspectionVerified
    }
}

public struct LocationData: Codable {
    var coordinate: CoordinateData
    var heading: Double?
    var speed: Double?
    var timestamp: Date
    
    init(coordinate: CLLocationCoordinate2D, heading: Double? = nil, speed: Double? = nil) {
        self.coordinate = CoordinateData(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.heading = heading
        self.speed = speed
        self.timestamp = Date()
    }
}

struct CoordinateData: Codable {
    var latitude: Double
    var longitude: Double
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
