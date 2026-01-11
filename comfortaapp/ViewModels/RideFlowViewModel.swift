import Foundation
import Combine
import MapKit
import CoreLocation

@MainActor
final class RideFlowViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStatus: TripStatus = .requested
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
        if let driver = assignedDriver,
           let coordinate = driver.currentCoordinate {
            annotations.append(RideMapAnnotation(
                coordinate: coordinate,
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
        let phone = driver.phoneNumber ?? "N/A"
        print("Calling driver: \(driver.name) at \(phone)")
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + findDriverDelay) { [weak self] in
            guard let self else { return }
            guard self.currentStatus != .cancelled else { return }
            self.assignDriver()
        }
    }
    
    private func assignDriver() {
        let vehicleOptions = [
            ("Toyota", "Prius"),
            ("Nissan", "Leaf"),
            ("Honda", "Civic"),
            ("Volkswagen", "Golf")
        ]
        let selectedVehicle = vehicleOptions.randomElement()!
        let vehicleInfo = VehicleInfo(
            make: selectedVehicle.0,
            model: selectedVehicle.1,
            year: Int.random(in: 2018...2024),
            color: ["Blanco", "Negro", "Gris", "Azul"].randomElement()!,
            licensePlate: generateRandomPlate(),
            capacity: 4,
            vehicleType: .sedan
        )
        
        var mockDriver = Driver(
            userId: UUID().uuidString,
            licenseNumber: "LIC\(Int.random(in: 10000...99999))",
            name: ["Carlos", "María", "David", "Ana", "Luis"].randomElement()!,
            vehicleInfo: vehicleInfo
        )
        
        mockDriver.rating = Double.random(in: 4.2...4.9)
        mockDriver.phoneNumber = "+34 6\(String(format: "%08d", Int.random(in: 10000000...99999999)))"
        mockDriver.currentLocation = LocationData(coordinate: generateDriverLocation())
        mockDriver.estimatedArrival = Double.random(in: 300...900) // 5-15 minutes
        
        assignedDriver = mockDriver
        currentStatus = .driverAssigned
        calculateEstimatedArrival()
        
        // Simulate driver en route after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            guard self.currentStatus != .cancelled else { return }
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
        guard let driver = assignedDriver, driver.estimatedArrival > 0 else {
            estimatedArrivalTime = ""
            return
        }
        
        let minutes = Int(driver.estimatedArrival / 60)
        estimatedArrivalTime = "\(minutes) min"
    }
    
    private func startDriverLocationUpdates() {
        guard let driver = assignedDriver, driver.estimatedArrival > 0 else { return }
        
        // Simulate driver moving towards pickup
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDriverLocation()
            }
        }
        
        // Simulate driver arrival
        let arrivalTime = driver.estimatedArrival
        DispatchQueue.main.asyncAfter(deadline: .now() + arrivalTime) { [weak self] in
            guard let self else { return }
            guard self.currentStatus != .cancelled else { return }
            self.driverArrived()
        }
    }
    
    private func updateDriverLocation() {
        guard var driver = assignedDriver,
              let currentCoordinate = driver.currentCoordinate else { return }
        
        // Move driver slightly closer to pickup
        let pickupLat = tripData.pickupCoordinate.latitude
        let pickupLon = tripData.pickupCoordinate.longitude
        let currentLat = currentCoordinate.latitude
        let currentLon = currentCoordinate.longitude
        
        let latDiff = (pickupLat - currentLat) * 0.1
        let lonDiff = (pickupLon - currentLon) * 0.1
        
        let newLocation = CLLocationCoordinate2D(
            latitude: currentLat + latDiff,
            longitude: currentLon + lonDiff
        )
        
        driver.currentLocation = LocationData(coordinate: newLocation)
        if driver.estimatedArrival > 60 {
            driver.estimatedArrival = max(driver.estimatedArrival - 300, 60)
        }
        
        assignedDriver = driver
        calculateEstimatedArrival()
    }
    
    private func driverArrived() {
        guard currentStatus != .cancelled else { return }
        statusTimer?.invalidate()
        currentStatus = .driverArrived
        estimatedArrivalTime = "Ha llegado"
        
        // Simulate trip start after 1-3 minutes
        let startDelay = Double.random(in: 60...180)
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) { [weak self] in
            guard let self else { return }
            guard self.currentStatus == .driverArrived else { return }
            self.startTrip()
        }
    }
    
    private func startTrip() {
        guard currentStatus != .cancelled else { return }
        currentStatus = .inProgress
        
        // Simulate trip duration based on estimated duration
        let tripDurationString = tripData.estimatedDuration
        let tripDuration = parseDuration(tripDurationString)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tripDuration) { [weak self] in
            guard let self else { return }
            guard self.currentStatus == .inProgress else { return }
            self.completeTrip()
        }
    }
    
    private func completeTrip() {
        currentStatus = .completed
        statusTimer?.invalidate()
    }
    
    private func parseDuration(_ durationString: String) -> TimeInterval {
        // Parse duration string like "8 min" or "1h 5m"
        let pattern = "(\\d+)\\s*(h|hr|hrs|hour|hours|m|min|mins)"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = durationString as NSString
        var totalSeconds: TimeInterval = 0
        
        regex?.matches(in: durationString, options: [], range: NSRange(location: 0, length: nsString.length)).forEach { match in
            let valueString = nsString.substring(with: match.range(at: 1))
            let unit = nsString.substring(with: match.range(at: 2)).lowercased()
            
            guard let value = Int(valueString) else { return }
            if unit.hasPrefix("h") {
                totalSeconds += TimeInterval(value * 3600)
            } else {
                totalSeconds += TimeInterval(value * 60)
            }
        }
        
        // Fallback if format is just a number
        if totalSeconds == 0,
           let minutes = Int(durationString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) {
            totalSeconds = TimeInterval(minutes * 60)
        }
        
        return max(totalSeconds, 300) // Minimum 5 minutes for demo
    }
    
    deinit {
        statusTimer?.invalidate()
    }
}
