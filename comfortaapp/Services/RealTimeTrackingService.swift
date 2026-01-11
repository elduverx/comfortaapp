import Foundation
import CoreLocation
import Combine
import MapKit

class RealTimeTrackingService: NSObject, ObservableObject {
    static let shared = RealTimeTrackingService()
    
    @Published var isTracking = false
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var estimatedArrival: Date?
    @Published var routePolyline: MKPolyline?
    @Published var distanceToDestination: Double = 0
    @Published var trackingError: String?
    
    private var locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()
    private var activeTrip: Trip?
    private var trackingTimer: Timer?
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Manager Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    // MARK: - Trip Tracking
    
    func startTracking(for trip: Trip) {
        guard !isTracking else { return }
        
        activeTrip = trip
        isTracking = true
        trackingError = nil
        
        // Request location permission if needed
        requestLocationPermission { [weak self] granted in
            if granted {
                self?.locationManager.startUpdatingLocation()
                self?.startTrackingTimer()
                self?.calculateInitialRoute()
            } else {
                self?.trackingError = "Permisos de ubicación requeridos para el seguimiento"
                self?.stopTracking()
            }
        }
        
        AnalyticsService.shared.track(.trackingStarted, metadata: [
            "trip_id": trip.id
        ])
    }
    
    func stopTracking() {
        isTracking = false
        activeTrip = nil
        trackingTimer?.invalidate()
        trackingTimer = nil
        locationManager.stopUpdatingLocation()
        
        AnalyticsService.shared.track(.trackingStopped)
    }
    
    // MARK: - Location Permission
    
    private func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            completion(true)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Completion will be called in delegate method
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Route Calculation
    
    private func calculateInitialRoute() {
        guard let trip = activeTrip,
              let currentLocation = currentLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: trip.destinationLocation.coordinate.clLocationCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                if let route = response?.routes.first {
                    self?.routePolyline = route.polyline
                    self?.distanceToDestination = route.distance / 1000.0 // Convert to km
                    self?.estimatedArrival = Date().addingTimeInterval(route.expectedTravelTime)
                } else if let error = error {
                    self?.trackingError = "Error calculando ruta: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateRoute() {
        calculateInitialRoute()
    }
    
    // MARK: - Tracking Timer
    
    private func startTrackingTimer() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendLocationUpdate()
            self?.updateRoute()
            self?.simulateDriverMovement()
        }
    }
    
    // MARK: - Location Updates
    
    private func sendLocationUpdate() {
        guard let trip = activeTrip,
              let location = currentLocation else { return }
        
        TripBookingService.shared.addLocationUpdate(trip.id, location: location)
    }
    
    // MARK: - Driver Simulation (for demo purposes)
    
    private func simulateDriverMovement() {
        guard let trip = activeTrip else { return }
        
        // Simulate driver moving towards pickup location
        if trip.status == .driverEnRoute || trip.status == .driverAssigned {
            let pickupLocation = trip.pickupLocation.coordinate.clLocationCoordinate
            
            if driverLocation == nil {
                // Start driver 2km away from pickup
                driverLocation = CLLocationCoordinate2D(
                    latitude: pickupLocation.latitude + 0.018, // Approximately 2km
                    longitude: pickupLocation.longitude + 0.018
                )
            } else {
                // Move driver closer to pickup
                moveDriverTowards(pickupLocation)
            }
        }
        // Simulate driver moving towards destination during trip
        else if trip.status == .inProgress {
            let destinationLocation = trip.destinationLocation.coordinate.clLocationCoordinate
            moveDriverTowards(destinationLocation)
        }
    }
    
    private func moveDriverTowards(_ target: CLLocationCoordinate2D) {
        guard let currentDriverLocation = driverLocation else { return }
        
        let latDiff = target.latitude - currentDriverLocation.latitude
        let lonDiff = target.longitude - currentDriverLocation.longitude
        
        // Move 10% of the way to target each update
        let moveRatio = 0.1
        
        driverLocation = CLLocationCoordinate2D(
            latitude: currentDriverLocation.latitude + (latDiff * moveRatio),
            longitude: currentDriverLocation.longitude + (lonDiff * moveRatio)
        )
        
        // Check if arrived at target
        let distance = CLLocation(latitude: currentDriverLocation.latitude, longitude: currentDriverLocation.longitude)
            .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
        
        if distance < 100 { // Within 100 meters
            if let trip = activeTrip {
                if trip.status == .driverEnRoute {
                    // Driver arrived at pickup
                    TripBookingService.shared.updateTripStatus(trip.id, status: .driverArrived)
                    NotificationService.shared.scheduleDriverArrivedNotification(for: trip)
                } else if trip.status == .inProgress {
                    // Trip completed
                    TripBookingService.shared.updateTripStatus(trip.id, status: .completed)
                    NotificationService.shared.scheduleTripCompletedNotification(for: trip)
                    stopTracking()
                }
            }
        }
    }
    
    // MARK: - Geofencing
    
    func setupGeofenceForPickup(_ trip: Trip) {
        let pickupCoordinate = trip.pickupLocation.coordinate.clLocationCoordinate
        let region = CLCircularRegion(
            center: pickupCoordinate,
            radius: 100, // 100 meter radius
            identifier: "pickup_\(trip.id)"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    func setupGeofenceForDestination(_ trip: Trip) {
        let destinationCoordinate = trip.destinationLocation.coordinate.clLocationCoordinate
        let region = CLCircularRegion(
            center: destinationCoordinate,
            radius: 100, // 100 meter radius
            identifier: "destination_\(trip.id)"
        )
        region.notifyOnEntry = true
        
        locationManager.startMonitoring(for: region)
    }
    
    private func removeGeofences(for trip: Trip) {
        let pickupIdentifier = "pickup_\(trip.id)"
        let destinationIdentifier = "destination_\(trip.id)"
        
        for region in locationManager.monitoredRegions {
            if region.identifier == pickupIdentifier || region.identifier == destinationIdentifier {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    // MARK: - Emergency Features
    
    func sendEmergencyAlert() {
        guard let trip = activeTrip,
              let location = currentLocation else { return }
        
        // In a real app, this would contact emergency services or trip monitoring
        print("EMERGENCY ALERT: Trip \(trip.id) at location \(location)")
        
        AnalyticsService.shared.track(.emergencyTriggered, metadata: [
            "trip_id": trip.id,
            "latitude": String(location.latitude),
            "longitude": String(location.longitude)
        ])
    }
    
    func shareLocationWithContact(_ contactInfo: String) {
        guard let trip = activeTrip,
              let location = currentLocation else { return }
        
        // In a real app, this would send location to emergency contact
        print("Sharing location with \(contactInfo): \(location)")
        
        AnalyticsService.shared.track(.locationShared, metadata: [
            "trip_id": trip.id
        ])
    }
}

// MARK: - CLLocationManagerDelegate

extension RealTimeTrackingService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location.coordinate
        
        // Update route if location changed significantly
        if let previousLocation = locations.dropLast().last,
           location.distance(from: previousLocation) > 50 {
            updateRoute()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isTracking {
                manager.startUpdatingLocation()
            }
        case .denied, .restricted:
            trackingError = "Permisos de ubicación denegados"
            stopTracking()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = activeTrip else { return }
        
        if region.identifier.hasPrefix("pickup_") {
            // Arrived at pickup location
            TripBookingService.shared.updateTripStatus(trip.id, status: .driverArrived)
            NotificationService.shared.scheduleDriverArrivedNotification(for: trip)
        } else if region.identifier.hasPrefix("destination_") {
            // Arrived at destination
            TripBookingService.shared.updateTripStatus(trip.id, status: .completed)
            NotificationService.shared.scheduleTripCompletedNotification(for: trip)
            stopTracking()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        trackingError = "Error de ubicación: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Geofence monitoring failed for region \(region?.identifier ?? "unknown"): \(error)")
    }
}
