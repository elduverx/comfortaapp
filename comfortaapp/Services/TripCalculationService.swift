import Foundation
import CoreLocation
import MapKit

public final class TripCalculationService {
    
    private let baseRate: Double = 1.50 // €1.50 per km
    private let longDistanceRate: Double = 1.10 // €1.10 per km for distances > 100km
    private let longDistanceThreshold: Double = 100 // km
    
    public init() {}
    
    public func calculateTrip(from pickup: LocationPoint, to destination: LocationPoint) async throws -> Trip {
        let distanceMeters = calculateDistance(from: pickup.coordinate, to: destination.coordinate)
        let fare = calculateFare(for: distanceMeters)
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
    
    func calculateFare(for distance: Double) -> Double {
        let distanceKm = distance / 1000
        
        guard distanceKm > 0 else { return 0 }
        
        if distanceKm <= longDistanceThreshold {
            return distanceKm * baseRate
        } else {
            let baseAmount = longDistanceThreshold * baseRate
            let extraDistance = distanceKm - longDistanceThreshold
            let extraAmount = extraDistance * longDistanceRate
            return baseAmount + extraAmount
        }
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
