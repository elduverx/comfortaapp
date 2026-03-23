import Foundation
import CoreLocation
import MapKit
import Combine

/// Servicio profesional de geocodificación inversa
/// Convierte coordenadas a direcciones legibles
@MainActor
final class ReverseGeocodingService: ObservableObject {

    // MARK: - Singleton
    static let shared = ReverseGeocodingService()

    // MARK: - Properties
    private let geocoder = CLGeocoder()

    // Cache para evitar consultas repetidas
    private var cache: [String: String] = [:]

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Convierte coordenadas a una dirección legible
    /// - Parameter coordinate: Coordenadas a convertir
    /// - Returns: Dirección formateada
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"

        // Check cache
        if let cached = cache[cacheKey] {
            return cached
        }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                throw ReverseGeocodingError.noResults
            }

            let address = formatAddress(from: placemark)

            // Cache result
            cache[cacheKey] = address

            return address
        } catch {
            throw ReverseGeocodingError.geocodingFailed(error)
        }
    }

    /// Obtiene una dirección detallada con información completa
    /// - Parameter coordinate: Coordenadas a convertir
    /// - Returns: Información detallada de la ubicación
    func reverseGeocodeDetailed(coordinate: CLLocationCoordinate2D) async throws -> LocationDetails {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                throw ReverseGeocodingError.noResults
            }

            return LocationDetails(
                address: formatAddress(from: placemark),
                street: placemark.thoroughfare,
                number: placemark.subThoroughfare,
                city: placemark.locality,
                postalCode: placemark.postalCode,
                country: placemark.country,
                coordinate: coordinate
            )
        } catch {
            throw ReverseGeocodingError.geocodingFailed(error)
        }
    }

    /// Limpia la cache
    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private Methods

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        // Street address
        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare {
                components.append("\(street) \(number)")
            } else {
                components.append(street)
            }
        }

        // City
        if let city = placemark.locality {
            components.append(city)
        }

        // Fallback to administrative area or country
        if components.isEmpty {
            if let area = placemark.administrativeArea {
                components.append(area)
            } else if let country = placemark.country {
                components.append(country)
            }
        }

        return components.isEmpty ? "Ubicación desconocida" : components.joined(separator: ", ")
    }
}

// MARK: - Supporting Types

/// Información detallada de una ubicación
struct LocationDetails {
    let address: String
    let street: String?
    let number: String?
    let city: String?
    let postalCode: String?
    let country: String?
    let coordinate: CLLocationCoordinate2D

    var shortAddress: String {
        if let street = street {
            return street
        }
        return address
    }

    var fullAddress: String {
        var parts: [String] = []

        if let street = street {
            if let number = number {
                parts.append("\(street) \(number)")
            } else {
                parts.append(street)
            }
        }

        if let city = city {
            parts.append(city)
        }

        if let postalCode = postalCode {
            parts.append(postalCode)
        }

        if let country = country {
            parts.append(country)
        }

        return parts.isEmpty ? address : parts.joined(separator: ", ")
    }
}

/// Errores de geocodificación
enum ReverseGeocodingError: LocalizedError {
    case noResults
    case geocodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No se encontraron resultados para esta ubicación"
        case .geocodingFailed(let error):
            return "Error de geocodificación: \(error.localizedDescription)"
        }
    }
}
