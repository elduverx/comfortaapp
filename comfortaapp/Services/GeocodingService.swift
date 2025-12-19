import Foundation
import CoreLocation
import MapKit

public class GeocodingService {
    
    public init() {}
    
    // Convertir dirección a coordenadas
    public func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let location = placemarks.first?.location else {
            throw GeocodingError.noResults
        }
        
        return location.coordinate
    }
    
    // Convertir coordenadas a dirección
    public func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw GeocodingError.noResults
        }
        
        return formatAddress(placemark)
    }
    
    // Legacy method for backward compatibility
    public func reverseGeocode(_ location: CLLocation) async throws -> String {
        return try await reverseGeocode(location.coordinate)
    }
    
    // Legacy method for backward compatibility
    public func geocode(_ address: String) async throws -> CLLocationCoordinate2D {
        return try await geocodeAddress(address)
    }
    
    private func formatAddress(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let number = placemark.subThoroughfare {
            components.append(number)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        return components.joined(separator: ", ")
    }
}

enum GeocodingError: Error {
    case noResults
    case invalidAddress
}