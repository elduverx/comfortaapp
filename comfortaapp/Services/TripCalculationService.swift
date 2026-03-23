import Foundation
import CoreLocation
import MapKit

public final class TripCalculationService {

    public init() {}

    public func calculateTrip(from pickup: LocationPoint, to destination: LocationPoint, includesAirport: Bool = false) async throws -> Trip {
        let distanceMeters = calculateDistance(from: pickup.coordinate, to: destination.coordinate)
        let includesAirportHub = includesAirport || PricingRules.hasAirportPortOrStation(
            origin: pickup.address,
            destination: destination.address
        )
        let fare = calculateFare(for: distanceMeters, includesAirport: includesAirportHub)
        let duration = try await estimateRouteTime(from: pickup, to: destination)

        let pickupInfo = LocationInfo(address: pickup.address, coordinate: pickup.coordinate)
        let destinationInfo = LocationInfo(address: destination.address, coordinate: destination.coordinate)
        let payment = PaymentMethodInfo(type: .cash, currency: "EUR", displayName: "Efectivo", isDefault: true)

        return Trip(
            userId: UserManager.shared.currentUser?.id ?? "",
            pickupLocation: pickupInfo,
            destinationLocation: destinationInfo,
            estimatedFare: fare,
            estimatedDistance: distanceMeters / 1000,
            estimatedDuration: duration,
            vehicleType: VehicleType.sedan.rawValue,
            paymentMethod: payment,
            specialRequests: [],
            scheduledAt: nil
        )
    }

    func calculateDistance(from pickup: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let pickupLocation = CLLocation(latitude: pickup.latitude, longitude: pickup.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)

        return pickupLocation.distance(from: destinationLocation)
    }

    /// Calcula la tarifa según la nueva formula de precios Comforta
    /// - Precio por km segun distancia: <50km 1.50, 50-100km 1.20, >100km 1.10
    /// - Minimo absoluto: 7.50
    /// - Minimo para viajes >= 10km: 15
    /// - Recargo aeropuerto/puerto/estacion: +8
    func calculateFare(for distance: Double, includesAirport: Bool = false) -> Double {
        let distanceKm = distance / 1000

        guard distanceKm > 0 else { return PricingRules.minimumFare }

        let pricePerKm = PricingRules.pricePerKm(for: distanceKm)
        var fare = distanceKm * pricePerKm
        fare = PricingRules.applyMinimums(to: fare, distanceKm: distanceKm)

        // Agregar recargo de aeropuerto si aplica
        if includesAirport {
            fare += PricingRules.airportSurcharge
        }

        // Redondear a 2 decimales
        return round(fare * 100) / 100
    }
    
    func estimateRouteTime(from pickup: LocationPoint, to destination: LocationPoint) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            return response.routes.first?.expectedTravelTime ?? estimateTravelTime(distance: calculateDistance(from: pickup.coordinate, to: destination.coordinate))
        } catch {
            // Fallback to simple estimation if route calculation fails
            return estimateTravelTime(distance: calculateDistance(from: pickup.coordinate, to: destination.coordinate))
        }
    }
    
    private func estimateTravelTime(distance: Double) -> TimeInterval {
        let distanceKm = distance / 1000
        let averageSpeedKmh: Double = 50 // Average city speed
        let timeHours = distanceKm / averageSpeedKmh
        return timeHours * 3600 // Convert to seconds
    }
}

// MARK: - Extensions for convenience

extension TripCalculationService {
    func formatDistance(_ distance: Double) -> String {
        let km = distance / 1000
        if km < 1 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", km)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
    
    func formatFare(_ fare: Double) -> String {
        return fare.formatted(.currency(code: "EUR").locale(Locale(identifier: "es_ES")))
    }
}
