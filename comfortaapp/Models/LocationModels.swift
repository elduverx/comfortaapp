import Foundation
import CoreLocation
import MapKit

// MARK: - Location Models

public struct LocationPoint: Codable, Hashable, Equatable {
    public let coordinate: CLLocationCoordinate2D
    public let address: String
    public let name: String?
    public let timestamp: Date
    
    public init(coordinate: CLLocationCoordinate2D, address: String, name: String? = nil) {
        self.coordinate = coordinate
        self.address = address
        self.name = name
        self.timestamp = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, address, name, timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.address = try container.decode(String.self, forKey: .address)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public static func == (lhs: LocationPoint, rhs: LocationPoint) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.address == rhs.address &&
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(address)
        hasher.combine(name)
    }
}

public struct SearchSuggestion: Identifiable, Hashable {
    public let id = UUID()
    public let completion: MKLocalSearchCompletion
    
    public var title: String { completion.title }
    public var subtitle: String { completion.subtitle }
    public var fullAddress: String {
        [title, subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
    }
    
    public init(completion: MKLocalSearchCompletion) {
        self.completion = completion
    }
}

public enum SearchFieldType {
    case pickup
    case destination
    
    public var title: String {
        switch self {
        case .pickup: return "Recogida"
        case .destination: return "Destino"
        }
    }
    
    public var icon: String {
        switch self {
        case .pickup: return "mappin.circle.fill"
        case .destination: return "flag.checkered"
        }
    }
    
    public var placeholder: String {
        switch self {
        case .pickup: return "Punto de recogida"
        case .destination: return "¿Dónde te llevamos?"
        }
    }
}
