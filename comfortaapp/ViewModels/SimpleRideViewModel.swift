import Foundation
import Combine
import MapKit
import CoreLocation
import SwiftUI

@MainActor
final class SimpleRideViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var pickupText: String = ""
    @Published var destinationText: String = ""
    @Published var pickupSuggestions: [MKLocalSearchCompletion] = []
    @Published var destinationSuggestions: [MKLocalSearchCompletion] = []
    @Published var isPickupFieldActive: Bool = false
    @Published var isDestinationFieldActive: Bool = false
    @Published var currentLocation: CLLocation?
    @Published var estimatedFare: String = "Introduce ubicaciones"
    @Published var estimatedDistance: String = ""
    @Published var estimatedDuration: String = ""
    @Published var errorMessage: String?
    @Published var routePolyline: MKPolyline?
    
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    // MARK: - Private Properties
    private let pickupCompleter = MKLocalSearchCompleter()
    private let destinationCompleter = MKLocalSearchCompleter()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    var pickupCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        setupCompleters()
    }
    
    // MARK: - Setup Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    private func setupCompleters() {
        // Setup pickup completer
        pickupCompleter.delegate = self
        pickupCompleter.resultTypes = [.address, .pointOfInterest]
        pickupCompleter.region = mapRegion
        
        // Setup destination completer
        destinationCompleter.delegate = self
        destinationCompleter.resultTypes = [.address, .pointOfInterest]
        destinationCompleter.region = mapRegion
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func activatePickupField() {
        print("🎯 Activating pickup field")
        isPickupFieldActive = true
        isDestinationFieldActive = false
        pickupSuggestions.removeAll() // Clear previous suggestions
    }
    
    func activateDestinationField() {
        isDestinationFieldActive = true
        isPickupFieldActive = false
        destinationSuggestions.removeAll() // Clear previous suggestions
    }
    
    func deactivateFields() {
        isPickupFieldActive = false
        isDestinationFieldActive = false
    }
    
    func clearTrip() {
        pickupText = ""
        destinationText = ""
        pickupCoordinate = nil
        destinationCoordinate = nil
        pickupSuggestions.removeAll()
        destinationSuggestions.removeAll()
        estimatedFare = "Introduce ubicaciones"
        estimatedDistance = ""
        estimatedDuration = ""
        routePolyline = nil
        deactivateFields()
    }
    
    func updatePickupText(_ text: String) {
        if text.count >= 2 {
            pickupCompleter.queryFragment = text
        } else {
            pickupSuggestions.removeAll()
        }
    }
    
    func updateDestinationText(_ text: String) {
        if text.count >= 2 {
            destinationCompleter.queryFragment = text
        } else {
            destinationSuggestions.removeAll()
        }
    }
    
    func selectPickupSuggestion(_ completion: MKLocalSearchCompletion) {
        Task {
            do {
                let coordinate = try await resolveCompletion(completion)
                
                await MainActor.run {
                    pickupCoordinate = coordinate
                    pickupText = completion.title + (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")
                    pickupSuggestions.removeAll()
                    isPickupFieldActive = false
                    updateMapRegion(to: coordinate)
                    calculateFare()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al seleccionar ubicación de recogida: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func selectDestinationSuggestion(_ completion: MKLocalSearchCompletion) {
        Task {
            do {
                let coordinate = try await resolveCompletion(completion)
                
                await MainActor.run {
                    destinationCoordinate = coordinate
                    destinationText = completion.title + (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")
                    destinationSuggestions.removeAll()
                    isDestinationFieldActive = false
                    updateMapRegion(to: coordinate)
                    calculateFare()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al seleccionar ubicación de destino: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func useCurrentLocation() {
        guard let location = currentLocation else {
            locationManager.requestLocation()
            return
        }
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    let address = formatAddress(from: placemark)
                    pickupText = address
                    pickupCoordinate = location.coordinate
                    updateMapRegion(to: location.coordinate)
                    calculateFare()
                    print("✅ Using current location: \(address)")
                }
            } catch {
                errorMessage = "Error al obtener dirección actual"
            }
        }
    }
    
    // MARK: - Private Methods
    private func resolveCompletion(_ completion: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let coordinate = response.mapItems.first?.placemark.coordinate else {
            throw NSError(domain: "SearchError", code: 0)
        }
        
        return coordinate
    }
    
    private func updateMapRegion(to coordinate: CLLocationCoordinate2D) {
        mapRegion.center = coordinate
        pickupCompleter.region = mapRegion
        destinationCompleter.region = mapRegion
    }
    
    private func calculateFare() {
        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else {
            estimatedFare = "Selecciona ubicaciones"
            estimatedDistance = ""
            estimatedDuration = ""
            routePolyline = nil
            return
        }
        
        print("🧮 Starting route calculation...")
        
        Task {
            do {
                let route = try await calculateRoute(from: pickup, to: destination)
                
                await MainActor.run {
                    let distanceKm = route.distance / 1000
                    let fare = calculateFareAmount(for: distanceKm)
                    
                    estimatedDistance = String(format: "%.1f km", distanceKm)
                    estimatedFare = fare.formatted(.currency(code: "EUR").locale(Locale(identifier: "es_ES")))
                    estimatedDuration = formatDuration(route.expectedTravelTime)
                    routePolyline = route.polyline
                    
                    // Update map region to show both points
                    updateMapRegionForRoute(pickup: pickup, destination: destination)
                    
                    print("💰 Route calculated: \(estimatedFare) for \(estimatedDistance) in \(estimatedDuration)")
                }
            } catch {
                await MainActor.run {
                    // Fallback to straight-line calculation
                    let pickupLocation = CLLocation(latitude: pickup.latitude, longitude: pickup.longitude)
                    let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
                    let distance = pickupLocation.distance(from: destinationLocation)
                    let distanceKm = distance / 1000
                    
                    let fare = calculateFareAmount(for: distanceKm)
                    
                    estimatedDistance = String(format: "%.1f km (línea recta)", distanceKm)
                    estimatedFare = fare.formatted(.currency(code: "EUR").locale(Locale(identifier: "es_ES")))
                    estimatedDuration = formatDuration(distanceKm * 60) // Estimate 1 km per minute
                    
                    updateMapRegionForRoute(pickup: pickup, destination: destination)
                    
                    print("💰 Fallback calculation: \(estimatedFare) for \(estimatedDistance)")
                }
            }
        }
    }
    
    private func calculateRoute(from pickup: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw NSError(domain: "RouteError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No route found"])
        }
        
        return route
    }
    
    private func updateMapRegionForRoute(pickup: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let coordinates = [pickup, destination]
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
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func calculateFareAmount(for distanceKm: Double) -> Double {
        if distanceKm <= 100 {
            return distanceKm * 1.5
        } else {
            return (100 * 1.5) + ((distanceKm - 100) * 1.1)
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        return components.isEmpty ? "Ubicación actual" : components.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate

extension SimpleRideViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Permisos de ubicación denegados"
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        updateMapRegion(to: location.coordinate)
        print("📍 Location updated: \(location.coordinate)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Error al obtener ubicación: \(error.localizedDescription)"
        print("❌ Location error: \(error)")
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension SimpleRideViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            if completer == self.pickupCompleter {
                self.pickupSuggestions = completer.results
            } else if completer == self.destinationCompleter {
                self.destinationSuggestions = completer.results
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        let type = completer == pickupCompleter ? "Pickup" : "Destination"
        print("❌ \(type) completer error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            if completer == self.pickupCompleter {
                self.pickupSuggestions.removeAll()
            } else if completer == self.destinationCompleter {
                self.destinationSuggestions.removeAll()
            }
        }
    }
}