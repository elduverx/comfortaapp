import Foundation
import Combine
import MapKit
import CoreLocation

@MainActor
final class RideFlowViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStatus: RideStatus = .requested
    @Published var tripData: TripData
    @Published var assignedDriver: Driver?
    @Published var showingCancellationAlert = false
    @Published var mapRegion: MKCoordinateRegion
    @Published var estimatedArrivalTime: String = ""
    
    // MARK: - Private Properties
    private var statusTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(tripData: TripData) {
        self.tripData = tripData
        self.mapRegion = MKCoordinateRegion(
            center: tripData.pickupCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        setupMapRegion()
    }
    
    // MARK: - Computed Properties
    var mapAnnotations: [RideMapAnnotation] {
        var annotations: [RideMapAnnotation] = []
        
        // Always show pickup and destination
        annotations.append(RideMapAnnotation(
            coordinate: tripData.pickupCoordinate,
            type: .pickup,
            title: "Recogida"
        ))
        
        annotations.append(RideMapAnnotation(
            coordinate: tripData.destinationCoordinate,
            type: .destination,
            title: "Destino"
        ))
        
        // Show driver if assigned
        if let driver = assignedDriver {
            annotations.append(RideMapAnnotation(
                coordinate: driver.currentLocation,
                type: .driver,
                title: driver.name
            ))
        }
        
        return annotations
    }
    
    // MARK: - Public Methods
    func startTripFlow() {
        // Simulate trip progression
        simulateTripProgress()
    }
    
    func cancelTrip() {
        guard currentStatus != .inProgress && currentStatus != .completed else {
            return
        }
        
        statusTimer?.invalidate()
        currentStatus = .cancelled
        showingCancellationAlert = true
    }
    
    func showHelp() {
        // Implement help functionality
        print("Help requested")
    }
    
    func callDriver() {
        guard let driver = assignedDriver else { return }
        // Implement call functionality
        print("Calling driver: \(driver.name) at \(driver.phoneNumber)")
    }
    
    func messageDriver() {
        guard let driver = assignedDriver else { return }
        // Implement messaging functionality
        print("Messaging driver: \(driver.name)")
    }
    
    func reportIssue() {
        // Implement issue reporting
        print("Report issue requested")
    }
    
    // MARK: - Private Methods
    private func setupMapRegion() {
        // Calculate region to show both pickup and destination
        let coordinates = [tripData.pickupCoordinate, tripData.destinationCoordinate]
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    private func simulateTripProgress() {
        // Simulate finding a driver (3-8 seconds)
        let findDriverDelay = Double.random(in: 3...8)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + findDriverDelay) {
            self.assignDriver()
        }
    }
    
    private func assignDriver() {
        // Create mock driver
        let mockDriver = Driver(
            id: UUID().uuidString,
            name: ["Carlos", "María", "David", "Ana", "Luis"].randomElement()!,
            rating: Double.random(in: 4.2...4.9),
            vehicleModel: ["Toyota Prius", "Nissan Leaf", "Honda Civic", "Volkswagen Golf"].randomElement()!,
            vehiclePlate: generateRandomPlate(),
            vehicleColor: ["Blanco", "Negro", "Gris", "Azul"].randomElement()!,
            phoneNumber: "+34 6\(String(format: "%08d", Int.random(in: 10000000...99999999)))",
            currentLocation: generateDriverLocation(),
            estimatedArrival: Double.random(in: 300...900) // 5-15 minutes
        )
        
        assignedDriver = mockDriver
        currentStatus = .driverAssigned
        calculateEstimatedArrival()
        
        // Simulate driver en route after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentStatus = .driverEnRoute
            self.startDriverLocationUpdates()
        }
    }
    
    private func generateRandomPlate() -> String {
        let numbers = String(format: "%04d", Int.random(in: 1000...9999))
        let letters = ["A", "B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "R", "S", "T", "V", "W", "X", "Y", "Z"]
        let randomLetters = (0..<3).map { _ in letters.randomElement()! }.joined()
        return "\(numbers) \(randomLetters)"
    }
    
    private func generateDriverLocation() -> CLLocationCoordinate2D {
        // Generate location within 2-5km of pickup
        let distance = Double.random(in: 0.02...0.05) // Roughly 2-5km
        let angle = Double.random(in: 0...(2 * Double.pi))
        
        return CLLocationCoordinate2D(
            latitude: tripData.pickupCoordinate.latitude + (distance * cos(angle)),
            longitude: tripData.pickupCoordinate.longitude + (distance * sin(angle))
        )
    }
    
    private func calculateEstimatedArrival() {
        guard let driver = assignedDriver else { return }
        
        let minutes = Int(driver.estimatedArrival / 60)
        estimatedArrivalTime = "\(minutes) min"
    }
    
    private func startDriverLocationUpdates() {
        guard let driver = assignedDriver else { return }
        
        // Simulate driver moving towards pickup
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateDriverLocation()
            }
        }
        
        // Simulate driver arrival
        let arrivalTime = driver.estimatedArrival
        DispatchQueue.main.asyncAfter(deadline: .now() + arrivalTime) {
            self.driverArrived()
        }
    }
    
    private func updateDriverLocation() {
        guard let driver = assignedDriver else { return }
        
        // Move driver slightly closer to pickup
        let pickupLat = tripData.pickupCoordinate.latitude
        let pickupLon = tripData.pickupCoordinate.longitude
        let currentLat = driver.currentLocation.latitude
        let currentLon = driver.currentLocation.longitude
        
        let latDiff = (pickupLat - currentLat) * 0.1
        let lonDiff = (pickupLon - currentLon) * 0.1
        
        let newLocation = CLLocationCoordinate2D(
            latitude: currentLat + latDiff,
            longitude: currentLon + lonDiff
        )
        
        // Update driver location
        let updatedDriver = Driver(
            id: driver.id,
            name: driver.name,
            rating: driver.rating,
            vehicleModel: driver.vehicleModel,
            vehiclePlate: driver.vehiclePlate,
            vehicleColor: driver.vehicleColor,
            phoneNumber: driver.phoneNumber,
            photoURL: driver.photoURL,
            currentLocation: newLocation,
            estimatedArrival: max(driver.estimatedArrival - 300, 60) // Decrease arrival time
        )
        
        assignedDriver = updatedDriver
        calculateEstimatedArrival()
    }
    
    private func driverArrived() {
        statusTimer?.invalidate()
        currentStatus = .driverArrived
        estimatedArrivalTime = "Ha llegado"
        
        // Simulate trip start after 1-3 minutes
        let startDelay = Double.random(in: 60...180)
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
            self.startTrip()
        }
    }
    
    private func startTrip() {
        currentStatus = .inProgress
        
        // Simulate trip duration based on estimated duration
        let tripDurationString = tripData.estimatedDuration
        let tripDuration = parseDuration(tripDurationString)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tripDuration) {
            self.completeTrip()
        }
    }
    
    private func completeTrip() {
        currentStatus = .completed
        statusTimer?.invalidate()
    }
    
    private func parseDuration(_ durationString: String) -> TimeInterval {
        // Parse duration string like "8 min" or "1h 5m"
        let components = durationString.components(separatedBy: " ")
        var totalSeconds: TimeInterval = 0
        
        for component in components {
            if component.contains("min") || component.contains("m") {
                if let minutes = Int(component.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) {
                    totalSeconds += TimeInterval(minutes * 60)
                }
            } else if component.contains("h") {
                if let hours = Int(component.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) {
                    totalSeconds += TimeInterval(hours * 3600)
                }
            }
        }
        
        return max(totalSeconds, 300) // Minimum 5 minutes for demo
    }
    
    deinit {
        statusTimer?.invalidate()
    }
}