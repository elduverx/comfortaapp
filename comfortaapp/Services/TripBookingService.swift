import Foundation
import CoreLocation
import Combine

class TripBookingService: ObservableObject {
    static let shared = TripBookingService()
    
    @Published var activeTrip: Trip?
    @Published var tripHistory: [Trip] = []
    @Published var isBookingTrip = false
    @Published var bookingError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTripHistory()
    }
    
    // MARK: - Trip Booking
    
    func bookTrip(
        pickupLocation: LocationInfo,
        destinationLocation: LocationInfo,
        vehicleType: VehicleType,
        paymentMethod: PaymentMethodInfo,
        specialRequests: [String] = [],
        scheduledAt: Date? = nil
    ) -> AnyPublisher<Trip, Error> {
        isBookingTrip = true
        bookingError = nil
        
        return Future<Trip, Error> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let self = self else {
                    promise(.failure(TripBookingError.serviceUnavailable))
                    return
                }
                
                // Calculate fare using existing pricing service
                let distance = self.calculateDistance(
                    from: pickupLocation.coordinate.clLocationCoordinate,
                    to: destinationLocation.coordinate.clLocationCoordinate
                )
                let includesAirportHub = PricingRules.hasAirportPortOrStation(
                    origin: pickupLocation.address,
                    destination: destinationLocation.address
                )
                let baseFare = PricingService.shared.calculateFare(
                    distance: distance,
                    vehicleType: vehicleType.rawValue,
                    includesAirport: includesAirportHub
                )
                let duration = distance / 60 * 60 // Rough estimate
                
                let trip = Trip(
                    userId: UserManager.shared.currentUser?.id ?? "",
                    pickupLocation: pickupLocation,
                    destinationLocation: destinationLocation,
                    estimatedFare: baseFare,
                    estimatedDistance: distance,
                    estimatedDuration: duration,
                    vehicleType: vehicleType.rawValue,
                    paymentMethod: paymentMethod,
                    specialRequests: specialRequests,
                    scheduledAt: scheduledAt
                )
                
                self.activeTrip = trip
                self.tripHistory.append(trip)
                self.saveTripHistory()
                
                self.isBookingTrip = false
                promise(.success(trip))
                
                // Start trip simulation
                self.simulateTripProgress(trip: trip)
                
                AnalyticsService.shared.track(.tripBooked, metadata: [
                    "trip_id": trip.id,
                    "vehicle_type": vehicleType.rawValue,
                    "payment_method": paymentMethod.type.rawValue,
                    "scheduled": scheduledAt != nil ? "true" : "false"
                ])
            }
        }
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.bookingError = error.localizedDescription
                    self?.isBookingTrip = false
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Trip Management
    
    func cancelTrip(_ tripId: String, reason: String? = nil) {
        guard let tripIndex = tripHistory.firstIndex(where: { $0.id == tripId }) else { return }
        
        tripHistory[tripIndex].status = .cancelled
        tripHistory[tripIndex].cancelledAt = Date()
        
        if activeTrip?.id == tripId {
            activeTrip = nil
        }
        
        saveTripHistory()
        
        AnalyticsService.shared.track(.tripCancelled, metadata: [
            "trip_id": tripId,
            "reason": reason ?? "user_cancelled"
        ])
    }
    
    func rateTrip(_ tripId: String, rating: Double, feedback: String?) {
        guard let tripIndex = tripHistory.firstIndex(where: { $0.id == tripId }) else { return }
        
        tripHistory[tripIndex].driverRating = rating
        tripHistory[tripIndex].driverFeedback = feedback
        
        saveTripHistory()
        
        AnalyticsService.shared.track(.tripRated, metadata: [
            "trip_id": tripId,
            "rating": String(rating)
        ])
    }
    
    func updateTripStatus(_ tripId: String, status: TripStatus) {
        guard let tripIndex = tripHistory.firstIndex(where: { $0.id == tripId }) else { return }
        
        let oldStatus = tripHistory[tripIndex].status
        tripHistory[tripIndex].status = status
        
        switch status {
        case .inProgress:
            tripHistory[tripIndex].pickedUpAt = Date()
        case .completed:
            tripHistory[tripIndex].droppedOffAt = Date()
            if activeTrip?.id == tripId {
                activeTrip = nil
            }
        default:
            break
        }
        
        saveTripHistory()
        
        AnalyticsService.shared.track(.tripStatusChanged, metadata: [
            "trip_id": tripId,
            "old_status": oldStatus.rawValue,
            "new_status": status.rawValue
        ])
    }
    
    // MARK: - Real-time Tracking
    
    func addLocationUpdate(_ tripId: String, location: CLLocationCoordinate2D) {
        guard let tripIndex = tripHistory.firstIndex(where: { $0.id == tripId }),
              let userId = UserManager.shared.currentUser?.id else { return }
        
        let locationUpdate = LocationUpdate(
            tripId: tripId,
            userId: userId,
            coordinate: location
        )
        
        tripHistory[tripIndex].realTimeTracking.append(locationUpdate)
        
        // Keep only last 100 location updates to avoid memory issues
        if tripHistory[tripIndex].realTimeTracking.count > 100 {
            tripHistory[tripIndex].realTimeTracking.removeFirst()
        }
        
        saveTripHistory()
    }
    
    // MARK: - Trip History
    
    func getTripHistory(limit: Int? = nil) -> [Trip] {
        let sorted = tripHistory.sorted { $0.createdAt > $1.createdAt }
        if let limit = limit {
            return Array(sorted.prefix(limit))
        }
        return sorted
    }
    
    func getTrip(by id: String) -> Trip? {
        return tripHistory.first { $0.id == id }
    }
    
    func getActiveTrip() -> Trip? {
        return activeTrip
    }
    
    // MARK: - Private Helpers
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
    
    private func simulateTripProgress(trip: Trip) {
        // Simulate driver assignment after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.updateTripStatus(trip.id, status: .driverAssigned)
        }
        
        // Simulate driver en route after 1 minute
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.updateTripStatus(trip.id, status: .driverEnRoute)
        }
        
        // Simulate driver arrival after 10 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 600) { [weak self] in
            self?.updateTripStatus(trip.id, status: .driverArrived)
        }
    }
    
    // MARK: - Persistence
    
    private func saveTripHistory() {
        if let encoded = try? JSONEncoder().encode(tripHistory) {
            UserDefaults.standard.set(encoded, forKey: "trip_history")
        }
    }
    
    private func loadTripHistory() {
        if let data = UserDefaults.standard.data(forKey: "trip_history"),
           let trips = try? JSONDecoder().decode([Trip].self, from: data) {
            self.tripHistory = trips
            self.activeTrip = trips.first { trip in
                ![TripStatus.completed, .cancelled, .failed].contains(trip.status)
            }
        }
    }
}

// MARK: - Trip Booking Errors

enum TripBookingError: LocalizedError {
    case invalidLocation
    case noDriversAvailable
    case paymentFailed
    case serviceUnavailable
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Ubicación inválida"
        case .noDriversAvailable:
            return "No hay conductores disponibles en este momento"
        case .paymentFailed:
            return "Error en el procesamiento del pago"
        case .serviceUnavailable:
            return "Servicio temporalmente no disponible"
        case .networkError:
            return "Error de conexión"
        }
    }
}
