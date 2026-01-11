import Foundation
import CoreLocation

// MARK: - Auth Models

struct LoginAppleRequest: Codable {
    let identityToken: String
    let authorizationCode: String?
    let user: AppleUserInfo?

    struct AppleUserInfo: Codable {
        let name: NameComponents?
        let email: String?

        struct NameComponents: Codable {
            let firstName: String?
            let lastName: String?
        }
    }
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: APIUser
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct LogoutRequest: Codable {
    let refreshToken: String?
    let deviceToken: String?
}

// MARK: - User Models

struct APIUser: Codable {
    let id: String
    let email: String?
    let name: String?
    let telefono: String?
}

struct ProfileResponse: Codable {
    let profile: APIProfile
}

struct APIProfile: Codable {
    let id: String
    let name: String?
    let email: String?
    let telefono: String?
    let image: String?
    let emailVerified: String?
    let createdAt: String
    let updatedAt: String
    let stats: ProfileStats

    struct ProfileStats: Codable {
        let totalTrips: Int
        let completedTrips: Int
        let totalSpent: Double
    }
}

struct UpdateProfileRequest: Codable {
    let name: String?
    let telefono: String?
    let email: String?
}

// MARK: - Trip Models

struct CreateTripRequest: Codable {
    let lugarRecogida: String?
    let destino: String
    let fechaInicio: String // ISO 8601
    let fechaFin: String? // ISO 8601
    let franjaHoraria: String?
    let notas: String?
    let distanciaKm: Double?
    let precioBase: Double?
    let precioTotal: Double?
}

struct TripResponse: Codable {
    let trip: APITrip
}

struct TripsListResponse: Codable {
    let trips: [APITrip]
    let total: Int
    let hasMore: Bool
}

struct APITrip: Codable, Identifiable {
    let id: String
    let shortId: String?
    let nombreUsuario: String?
    let email: String?
    let telefono: String?
    let lugarRecogida: String?
    let destino: String
    let fechaInicio: String
    let fechaFin: String?
    let franjaHoraria: String?
    let duracion: String?
    let distanciaKm: Double?
    let precioBase: Double?
    let recargoAeropuerto: Double?
    let precioTotal: Double?
    let estado: String
    let pagado: Bool
    let numeroFactura: String?
    let paymentOrderId: String?
    let paymentAuthCode: String?
    let paymentMethod: String?
    let paymentDate: String?
    let paymentResponse: String?
    let notas: String?
    let notasAdmin: String?
    let createdAt: String
    let updatedAt: String?

    // Helper to convert to Trip model
    func toTrip() -> Trip? {
        guard let pickupLocation = createLocationInfo(from: lugarRecogida),
              let destinationLocation = createLocationInfo(from: destino),
              let startDate = ISO8601DateFormatter().date(from: fechaInicio) else {
            return nil
        }

        return Trip(
            userId: id,
            pickupLocation: pickupLocation,
            destinationLocation: destinationLocation,
            estimatedFare: precioTotal ?? 0,
            estimatedDistance: distanciaKm ?? 0,
            estimatedDuration: 0, // Not provided by API
            vehicleType: "sedan",
            paymentMethod: PaymentMethodInfo(
                type: .creditCard,
                displayName: paymentMethod
            ),
            scheduledAt: startDate
        )
    }

    private func createLocationInfo(from address: String?) -> LocationInfo? {
        guard let address = address else { return nil }
        return LocationInfo(
            address: address,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
    }
}

struct UpdateTripRequest: Codable {
    let notas: String?
    let telefono: String?
}

struct CancelTripRequest: Codable {
    let reason: String?
}

// MARK: - Pricing Models

struct CalculatePricingRequest: Codable {
    let origin: String?
    let destination: String
}

struct PricingAPIResponse: Codable {
    let distance: Double
    let basePrice: Double
    let airportSurcharge: Double
    let totalPrice: Double
    let pricePerKm: Double
}

// MARK: - Favorite Models

struct FavoritesResponse: Codable {
    let favorites: [APIFavorite]
}

struct FavoriteResponse: Codable {
    let favorite: APIFavorite
}

struct APIFavorite: Codable {
    let id: String
    let nombre: String
    let direccion: String
    let tipo: String
    let latitud: Double?
    let longitud: Double?
    let createdAt: String
    let updatedAt: String?
}

struct CreateFavoriteRequest: Codable {
    let nombre: String
    let direccion: String
    let tipo: String?
    let latitud: Double?
    let longitud: Double?
}

struct UpdateFavoriteRequest: Codable {
    let nombre: String?
    let direccion: String?
    let tipo: String?
    let latitud: Double?
    let longitud: Double?
}

// MARK: - Generic Response Models

struct MessageResponse: Codable {
    let message: String
}

// MARK: - Helpers

extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}
