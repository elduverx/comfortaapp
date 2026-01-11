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
    @Published var isCalculatingRoute: Bool = false
    @Published var currentTripState: TripState = .searchingLocations
    @Published var assignedDriver: Driver?
    @Published var currentTrip: Trip?
    
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    // MARK: - Private Properties
    private let pickupCompleter = MKLocalSearchCompleter()
    private let destinationCompleter = MKLocalSearchCompleter()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let pricingService = PricingServiceAPI.shared
    private let tripService = TripServiceAPI.shared
    private var pricingEstimate: PricingResponse?
    private var hasInitializedPickup = false
    
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
        pricingEstimate = nil
        routePolyline = nil
        currentTripState = .searchingLocations
        assignedDriver = nil
        currentTrip = nil
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
    
    func calculateFare() {
        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else {
            estimatedFare = "Selecciona ubicaciones"
            estimatedDistance = ""
            estimatedDuration = ""
            routePolyline = nil
            isCalculatingRoute = false
            return
        }

        print("🧮 Starting route calculation...")
        estimatedFare = "Calculando..."
        isCalculatingRoute = true

        let originAddress = pickupText.isEmpty ? nil : pickupText
        let destinationAddress = destinationText

        Task {
            let routeTask = Task { try await calculateRoute(from: pickup, to: destination) }
            let pricingTask = Task {
                try await pricingService.calculatePricing(
                    origin: originAddress,
                    destination: destinationAddress
                )
            }

            let route = try? await routeTask.value
            let pricing = try? await pricingTask.value

            await MainActor.run {
                let distanceKm: Double
                let duration: TimeInterval
                let distanceLabelSuffix: String

                if let route = route {
                    distanceKm = route.distance / 1000
                    duration = route.expectedTravelTime
                    distanceLabelSuffix = ""
                    routePolyline = route.polyline
                } else {
                    let pickupLocation = CLLocation(latitude: pickup.latitude, longitude: pickup.longitude)
                    let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
                    let distance = pickupLocation.distance(from: destinationLocation)
                    distanceKm = distance / 1000
                    duration = distanceKm * 60
                    distanceLabelSuffix = " (línea recta)"
                    routePolyline = nil
                }

                pricingEstimate = pricing

                let fare = pricing?.totalPrice ?? calculateFareAmount(for: distanceKm)

                estimatedDistance = String(format: "%.1f km%@", distanceKm, distanceLabelSuffix)
                estimatedFare = fare.formatted(.currency(code: "EUR").locale(Locale(identifier: "es_ES")))
                estimatedDuration = formatDuration(duration)

                updateMapRegionForRoute(pickup: pickup, destination: destination)

                print("💰 Route calculated: \(estimatedFare) for \(estimatedDistance) in \(estimatedDuration)")
                isCalculatingRoute = false

                createCurrentTrip()
                currentTripState = .readyToConfirm
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
    
    // MARK: - Public Setters
    func setPickup(address: String, coordinate: CLLocationCoordinate2D) {
        pickupText = address
        pickupCoordinate = coordinate
        updateMapRegion(to: coordinate)
        calculateFare()
    }
    
    func setDestination(address: String, coordinate: CLLocationCoordinate2D) {
        destinationText = address
        destinationCoordinate = coordinate
        updateMapRegion(to: coordinate)
        calculateFare()
    }
    
    func swapLocations() {
        guard let pickup = pickupCoordinate, let destination = destinationCoordinate else { return }
        let pickupTextCopy = pickupText
        let destinationTextCopy = destinationText
        pickupCoordinate = destination
        destinationCoordinate = pickup
        pickupText = destinationTextCopy
        destinationText = pickupTextCopy
        updateMapRegionForRoute(pickup: pickupCoordinate!, destination: destinationCoordinate!)
        calculateFare()
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
        
        if !hasInitializedPickup && pickupCoordinate == nil {
            hasInitializedPickup = true
            Task {
                do {
                    let placemarks = try await geocoder.reverseGeocodeLocation(location)
                    let address = placemarks.first.map { self.formatAddress(from: $0) } ?? "Ubicación actual"
                    await MainActor.run {
                        self.setPickup(address: address, coordinate: location.coordinate)
                    }
                } catch {
                    await MainActor.run {
                        self.setPickup(address: "Ubicación actual", coordinate: location.coordinate)
                    }
                }
            }
        }
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
    
    // MARK: - Trip Flow Methods
    
    func confirmTrip() {
        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else { return }
        
        currentTripState = .confirmingTrip
        
        // Simulate trip creation and driver assignment
        Task {
            await MainActor.run {
                currentTripState = .processingPayment
                errorMessage = nil
            }

            do {
                let apiTrip = try await tripService.createTrip(
                    pickupLocation: pickupText.isEmpty ? nil : pickupText,
                    destination: destinationText,
                    startDate: Date(),
                    notes: nil,
                    distanceKm: pricingEstimate?.distance ?? parseEstimatedDistance(),
                    basePrice: pricingEstimate?.basePrice,
                    totalPrice: pricingEstimate?.totalPrice ?? parseEstimatedFare()
                )

                await MainActor.run {
                    let pickupLocation = LocationInfo(
                        address: pickupText,
                        coordinate: pickup
                    )
                    let destinationLocation = LocationInfo(
                        address: destinationText,
                        coordinate: destination
                    )
                    let paymentMethod = PaymentMethodInfo(type: .cash)

                    currentTrip = Trip(
                        userId: AuthServiceAPI.shared.currentUser?.id ?? "user",
                        pickupLocation: pickupLocation,
                        destinationLocation: destinationLocation,
                        estimatedFare: apiTrip.precioTotal ?? parseEstimatedFare(),
                        estimatedDistance: apiTrip.distanciaKm ?? parseEstimatedDistance(),
                        estimatedDuration: parseEstimatedDuration(),
                        vehicleType: "Standard",
                        paymentMethod: paymentMethod
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al crear el viaje"
                    currentTripState = .readyToConfirm
                }
                return
            }

            await MainActor.run {
                currentTripState = .findingDriver
            }

            // Simulate finding driver
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

            await MainActor.run {
                // Create mock driver
                let mockVehicle = VehicleInfo(
                    make: "Tesla",
                    model: "Model Y",
                    year: 2023,
                    color: "Blanco",
                    licensePlate: "ABC1234",
                    capacity: 4,
                    vehicleType: .sedan
                )

                assignedDriver = Driver(
                    userId: "driver123",
                    licenseNumber: "ES123456789",
                    name: "Carlos Rodríguez",
                    vehicleInfo: mockVehicle
                )

                currentTripState = .driverAssigned
            }
        }
    }
    
    private func parseEstimatedFare() -> Double {
        if let pricing = pricingEstimate {
            return pricing.totalPrice
        }
        // Extract numeric value from "€25,50" format
        let cleanedString = estimatedFare.replacingOccurrences(of: "€", with: "")
                                      .replacingOccurrences(of: ",", with: ".")
        return Double(cleanedString) ?? 25.0
    }
    
    private func parseEstimatedDistance() -> Double {
        if let pricing = pricingEstimate {
            return pricing.distance
        }
        // Extract numeric value from "15.5 km" format
        let components = estimatedDistance.components(separatedBy: " ")
        if let firstComponent = components.first,
           let distance = Double(firstComponent.replacingOccurrences(of: ",", with: ".")) {
            return distance
        }
        return 15.0
    }
    
    private func parseEstimatedDuration() -> Double {
        // Simple parsing for now - in minutes
        return 25.0 * 60 // 25 minutes in seconds
    }
    
    private func createCurrentTrip() {
        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else { return }
        
        let pickupLocation = LocationInfo(
            address: pickupText,
            coordinate: pickup
        )
        let destinationLocation = LocationInfo(
            address: destinationText,
            coordinate: destination
        )
        let paymentMethod = PaymentMethodInfo(type: .cash)
        
        currentTrip = Trip(
            userId: "user123",
            pickupLocation: pickupLocation,
            destinationLocation: destinationLocation,
            estimatedFare: parseEstimatedFare(),
            estimatedDistance: parseEstimatedDistance(),
            estimatedDuration: parseEstimatedDuration(),
            vehicleType: "Standard",
            paymentMethod: paymentMethod
        )
    }
}

enum TripState {
    case searchingLocations
    case readyToConfirm
    case confirmingTrip
    case processingPayment
    case findingDriver
    case driverAssigned
    case driverEnRoute
    case driverArrived
    case inProgress
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .searchingLocations:
            return "Selecciona tus ubicaciones"
        case .readyToConfirm:
            return "Listo para confirmar"
        case .confirmingTrip:
            return "Confirmando viaje..."
        case .processingPayment:
            return "Procesando pago..."
        case .findingDriver:
            return "Buscando conductor..."
        case .driverAssigned:
            return "Conductor asignado"
        case .driverEnRoute:
            return "Conductor en camino"
        case .driverArrived:
            return "Conductor ha llegado"
        case .inProgress:
            return "Viaje en progreso"
        case .completed:
            return "Viaje completado"
        case .cancelled:
            return "Viaje cancelado"
        }
    }
}
