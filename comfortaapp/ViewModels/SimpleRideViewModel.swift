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
    @Published var requestedServiceDate: Date = Date()
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
    private let tripService = TripServiceAPI.shared
    private var cancellables = Set<AnyCancellable>()
    private var pricingEstimate: PricingResponse?
    private var hasInitializedPickup = false
    private var tripPollingTask: Task<Void, Never>?
    private var tripRefreshTask: Task<Void, Never>?
    private var persistenceCancellable: AnyCancellable?
    private let activeTripStorageKey = "active_trip_snapshot_v1"
    
    var pickupCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?

    var summaryFareText: String {
        if let actualFare = currentTrip?.actualFare {
            return formatFare(actualFare)
        }
        if let estimatedFareValue = currentTrip?.estimatedFare {
            return formatFare(estimatedFareValue)
        }
        if let totalPrice = pricingEstimate?.totalPrice {
            return formatFare(totalPrice)
        }
        return estimatedFare
    }

    private var shouldAllowTripPlanningUpdates: Bool {
        currentTripState == .searchingLocations || currentTripState == .readyToConfirm
    }

    var recentDestinations: [QuickDestination] {
        let trips = TripBookingService.shared.getTripHistory(limit: 10)
        var destinations: [QuickDestination] = []
        var seenAddresses = Set<String>()

        for trip in trips {
            let address = trip.destinationLocation.address
            if !seenAddresses.contains(address) {
                seenAddresses.insert(address)
                destinations.append(QuickDestination(
                    title: extractLocationName(from: address),
                    subtitle: address,
                    coordinate: trip.destinationLocation.clLocationCoordinate
                ))

                if destinations.count >= 5 {
                    break
                }
            }
        }

        return destinations
    }

    private func extractLocationName(from address: String) -> String {
        let components = address.components(separatedBy: ",")
        return components.first?.trimmingCharacters(in: .whitespaces) ?? address
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        setupCompleters()
        restoreActiveTripIfAvailable()
        setupTripPersistence()
        setupNotificationListeners()
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

    private func setupNotificationListeners() {
        NotificationCenter.default.publisher(for: .adminTripCompleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let tripId = notification.userInfo?["trip_id"] as? String else { return }
                let trip = notification.userInfo?["trip"] as? Trip
                self?.handleAdminTripCompleted(tripId: tripId, trip: trip)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .requestNewTrip)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.clearTrip()
            }
            .store(in: &cancellables)
    }

    private func handleAdminTripCompleted(tripId: String, trip: Trip?) {
        if let existingTrip = currentTrip, existingTrip.id == tripId {
            currentTrip?.status = .completed
            currentTripState = .completed
        } else if let trip = trip, currentTrip == nil {
            currentTrip = trip
            currentTripState = .completed
        }

        Task {
            if let apiTrip = try? await tripService.getTripStatus(tripId: tripId) {
                applyNotificationTrip(apiTrip)
            }
        }

        if shouldNotifyRideUpdates(), let trip = trip ?? currentTrip {
            NotificationService.shared.scheduleTripCompletedNotification(for: trip)
        }
    }

    private func setupTripPersistence() {
        persistenceCancellable = Publishers.CombineLatest3($currentTrip, $assignedDriver, $currentTripState)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.persistActiveTripIfNeeded()
            }
    }

    private func persistActiveTripIfNeeded() {
        guard let trip = currentTrip else {
            clearPersistedActiveTrip()
            return
        }

        if !shouldPersistActiveTrip(trip: trip) {
            clearPersistedActiveTrip()
            return
        }

        let snapshot = ActiveTripSnapshot(trip: trip, driver: assignedDriver)
        guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(encoded, forKey: activeTripStorageKey)
    }

    private func clearPersistedActiveTrip() {
        UserDefaults.standard.removeObject(forKey: activeTripStorageKey)
    }

    private func shouldPersistActiveTrip(trip: Trip) -> Bool {
        let blockedStates: Set<TripState> = [
            .searchingLocations,
            .readyToConfirm,
            .confirmingTrip,
            .processingPayment
        ]
        if blockedStates.contains(currentTripState) {
            return false
        }

        let terminalStatuses: Set<TripStatus> = [.completed, .cancelled, .failed]
        if terminalStatuses.contains(trip.status) {
            return false
        }

        return true
    }

    private func restoreActiveTripIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: activeTripStorageKey),
              let snapshot = try? JSONDecoder().decode(ActiveTripSnapshot.self, from: data) else {
            return
        }

        let trip = snapshot.trip
        if [.completed, .cancelled, .failed].contains(trip.status) {
            clearPersistedActiveTrip()
            return
        }

        currentTrip = trip
        assignedDriver = snapshot.driver
        pickupText = trip.pickupLocation.address
        destinationText = trip.destinationLocation.address
        pickupCoordinate = trip.pickupLocation.clLocationCoordinate
        destinationCoordinate = trip.destinationLocation.clLocationCoordinate
        estimatedFare = formatFare(trip.actualFare ?? trip.estimatedFare)
        estimatedDistance = String(format: "%.1f km", trip.actualDistance ?? trip.estimatedDistance)
        estimatedDuration = formatDuration(trip.actualDuration ?? trip.estimatedDuration)
        requestedServiceDate = trip.scheduledAt ?? trip.createdAt

        let hasDriver = assignedDriver != nil || trip.driverId?.isEmpty == false
        currentTripState = tripState(from: trip.status, hasDriver: hasDriver)

        if let pickup = pickupCoordinate, let destination = destinationCoordinate {
            updateMapRegionForRoute(pickup: pickup, destination: destination)
            Task { @MainActor in
                if let route = try? await calculateRoute(from: pickup, to: destination) {
                    routePolyline = route.polyline
                }
            }
        } else if let pickup = pickupCoordinate {
            updateMapRegion(to: pickup)
        }

        resumeTripMonitoringIfNeeded()
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
        requestedServiceDate = Date()
        assignedDriver = nil
        currentTrip = nil
        tripPollingTask?.cancel()
        tripPollingTask = nil
        tripRefreshTask?.cancel()
        tripRefreshTask = nil
        deactivateFields()
        clearPersistedActiveTrip()
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

        guard shouldAllowTripPlanningUpdates else {
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
        guard shouldAllowTripPlanningUpdates else {
            return
        }
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
            let route = try? await routeTask.value

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

                let pricing = buildPricingEstimate(distanceKm: distanceKm, duration: duration)
                pricingEstimate = pricing

                estimatedDistance = String(format: "%.1f km%@", distanceKm, distanceLabelSuffix)
                estimatedFare = pricing.totalPrice.formatted(.currency(code: "EUR").locale(Locale(identifier: "es_ES")))
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
        mapRegion = MKCoordinateRegion.regionToFit(
            coordinates: [pickup, destination],
            paddingFactor: 1.35,
            minimumSpan: 0.01
        )
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

    private func formatFare(_ amount: Double) -> String {
        amount.formatted(.currency(code: "EUR").locale(Locale(identifier: "es_ES")))
    }
    
    private func calculateFareAmount(for distanceKm: Double) -> Double {
        guard distanceKm > 0 else { return PricingRules.minimumFare }

        let pricePerKm = PricingRules.pricePerKm(for: distanceKm)
        var baseFare = distanceKm * pricePerKm
        baseFare = PricingRules.applyMinimums(to: baseFare, distanceKm: distanceKm)

        if PricingRules.hasAirportPortOrStation(origin: pickupText, destination: destinationText) {
            baseFare += PricingRules.airportSurcharge
        }

        return round(baseFare * 100) / 100
    }

    private func buildPricingEstimate(distanceKm: Double, duration: TimeInterval) -> PricingResponse {
        let pricePerKm = PricingRules.pricePerKm(for: distanceKm)
        let distanceFare = distanceKm * pricePerKm
        var basePrice = distanceFare
        basePrice = PricingRules.applyMinimums(to: basePrice, distanceKm: distanceKm)

        let airportSurcharge = PricingRules.hasAirportPortOrStation(
            origin: pickupText,
            destination: destinationText
        ) ? PricingRules.airportSurcharge : 0.0

        let totalPrice = basePrice + airportSurcharge

        return PricingResponse(
            distance: round(distanceKm * 10) / 10,
            estimatedTime: formatDuration(duration),
            basePrice: round(basePrice * 100) / 100,
            totalPrice: round(totalPrice * 100) / 100,
            priceBreakdown: PriceBreakdown(
                baseRate: round(basePrice * 100) / 100,
                distanceRate: round(distanceFare * 100) / 100,
                timeRate: 0,
                additionalFees: airportSurcharge
            )
        )
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
        guard shouldAllowTripPlanningUpdates else {
            return
        }
        pickupText = address
        pickupCoordinate = coordinate
        updateMapRegion(to: coordinate)
        calculateFare()
    }
    
    func setDestination(address: String, coordinate: CLLocationCoordinate2D) {
        guard shouldAllowTripPlanningUpdates else {
            return
        }
        destinationText = address
        destinationCoordinate = coordinate
        updateMapRegion(to: coordinate)
        calculateFare()
    }
    
    func swapLocations() {
        guard shouldAllowTripPlanningUpdates else {
            return
        }
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
        
        if shouldAllowTripPlanningUpdates && !hasInitializedPickup && pickupCoordinate == nil {
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

    func createPreviewTrip() {
        print("🔵 createPreviewTrip() llamado")
        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else {
            print("❌ Error: Coordenadas no disponibles para preview")
            errorMessage = "Por favor, selecciona ubicación de recogida y destino"
            return
        }

        print("✅ Creando preview de viaje...")

        let pickupLocation = LocationInfo(
            address: pickupText,
            coordinate: pickup
        )
        let destinationLocation = LocationInfo(
            address: destinationText,
            coordinate: destination
        )
        let paymentMethod = PaymentMethodInfo(type: .cash)

        // Create a temporary trip for preview
        currentTrip = Trip(
            id: UUID().uuidString,
            userId: AuthServiceAPI.shared.currentUser?.id ?? "user",
            status: .scheduled,
            pickupLocation: pickupLocation,
            destinationLocation: destinationLocation,
            estimatedFare: pricingEstimate?.totalPrice ?? parseEstimatedFare(),
            estimatedDistance: pricingEstimate?.distance ?? parseEstimatedDistance(),
            estimatedDuration: parseEstimatedDuration(),
            vehicleType: "Standard",
            paymentMethod: paymentMethod,
            createdAt: Date(),
            scheduledAt: requestedServiceDate
        )

        print("✅ Preview de viaje creado")
    }

    func handleTripNotification(tripId: String) {
        Task {
            do {
                let apiTrip = try await tripService.getTripDetails(id: tripId)
                await MainActor.run {
                    applyNotificationTrip(apiTrip)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "No se pudo cargar el viaje"
                }
                print("❌ Error loading trip from notification: \(error)")
            }
        }
    }

    func refreshTripStatusIfNeeded() {
        guard let tripId = currentTrip?.id else { return }

        switch currentTripState {
        case .searchingLocations, .readyToConfirm:
            return
        default:
            break
        }

        tripRefreshTask?.cancel()
        tripRefreshTask = Task { @MainActor in
            do {
                let apiTrip = try await tripService.getTripStatus(tripId: tripId)
                applyNotificationTrip(apiTrip)
            } catch {
                print("❌ Error refreshing trip status: \(error)")
            }
        }
    }

    func resumeTripMonitoringIfNeeded() {
        if currentTripState == .findingDriver {
            startPollingForDriverAssignment()
        } else {
            tripPollingTask?.cancel()
            tripPollingTask = nil
        }
    }

    func confirmTrip() {
        print("🔵 confirmTrip() llamado")
        print("🔵 Pickup coordinate: \(String(describing: pickupCoordinate))")
        print("🔵 Destination coordinate: \(String(describing: destinationCoordinate))")
        print("🔵 Pickup text: \(pickupText)")
        print("🔵 Destination text: \(destinationText)")

        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else {
            print("❌ Error: Coordenadas no disponibles")
            errorMessage = "Por favor, selecciona ubicación de recogida y destino"
            return
        }

        print("✅ Coordenadas válidas, iniciando creación de viaje...")
        currentTripState = .confirmingTrip

        // Real trip creation - wait for admin assignment
        Task {
            await MainActor.run {
                currentTripState = .processingPayment
                errorMessage = nil
            }

            print("📤 Enviando solicitud de viaje al backend...")

            do {
                let apiTrip = try await tripService.createTrip(
                    pickupLocation: pickupText.isEmpty ? nil : pickupText,
                    destination: destinationText,
                    pickupCoordinate: pickup,
                    destinationCoordinate: destination,
                    startDate: requestedServiceDate,
                    notes: nil,
                    distanceKm: pricingEstimate?.distance ?? parseEstimatedDistance(),
                    basePrice: pricingEstimate?.basePrice,
                    totalPrice: pricingEstimate?.totalPrice ?? parseEstimatedFare()
                )

                print("✅ Viaje creado con ID: \(apiTrip.id)")

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
                        id: apiTrip.id,
                        userId: AuthServiceAPI.shared.currentUser?.id ?? "user",
                        status: .requested,
                        pickupLocation: pickupLocation,
                        destinationLocation: destinationLocation,
                        estimatedFare: apiTrip.precioTotal ?? parseEstimatedFare(),
                        estimatedDistance: apiTrip.distanciaKm ?? parseEstimatedDistance(),
                        estimatedDuration: parseEstimatedDuration(),
                        vehicleType: "Standard",
                        paymentMethod: paymentMethod,
                        createdAt: Date(),
                        scheduledAt: requestedServiceDate
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al crear el viaje: \(error.localizedDescription)"
                    currentTripState = .readyToConfirm
                }
                return
            }

            // Move to finding driver state and wait for real assignment
            await MainActor.run {
                currentTripState = .findingDriver
                // NO simulation - real wait for admin to assign driver
                print("✅ Viaje creado - esperando asignación del administrador")
                startPollingForDriverAssignment()
            }
        }
    }

    private func startPollingForDriverAssignment() {
        guard tripPollingTask == nil else { return }

        tripPollingTask = Task { @MainActor in
            defer { tripPollingTask = nil }

            // Poll every 5 seconds to check if a driver has been assigned
            while currentTripState == .findingDriver && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                guard let tripId = currentTrip?.id else { break }

                // Check trip status from backend
                do {
                    let updatedTrip = try await tripService.getTripStatus(tripId: tripId)

                    let normalizedStatus = updatedTrip.estado
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                    let hasDriver = (updatedTrip.conductorId?.isEmpty == false)
                        || (updatedTrip.conductorNombre?.isEmpty == false)
                    let assignedStatuses: Set<String> = [
                        "ACEPTADO",
                        "ASSIGNED",
                        "ASIGNADO",
                        "EN_CAMINO",
                        "EN_RUTA",
                        "EN_ROUTE"
                    ]
                    let cancelledStatuses: Set<String> = [
                        "RECHAZADO",
                        "CANCELADO",
                        "EXPIRADO"
                    ]

                    if hasDriver || assignedStatuses.contains(normalizedStatus) {
                        // Driver has been assigned!
                        if assignedDriver == nil {
                            handleDriverAssigned(
                                driverId: updatedTrip.conductorId,
                                driverName: updatedTrip.conductorNombre
                            )
                        }
                    } else if cancelledStatuses.contains(normalizedStatus) {
                        // Trip was rejected or cancelled
                        if currentTripState != .cancelled {
                            handleTripRejected(reason: normalizedStatus)
                        }
                    }
                } catch {
                    print("❌ Error checking trip status: \(error)")
                }
            }
        }
    }

    private func applyNotificationTrip(_ apiTrip: APITrip) {
        let pickupAddress = apiTrip.lugarRecogida ?? "Recogida no especificada"
        let destinationAddress = apiTrip.destino
        let pickupCoordinate = coordinateFromAPI(lat: apiTrip.pickupLat, lng: apiTrip.pickupLng)
        let destinationCoordinate = coordinateFromAPI(lat: apiTrip.destinationLat, lng: apiTrip.destinationLng)
        let fallbackCoordinate = currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let pickupLocation = LocationInfo(address: pickupAddress, coordinate: pickupCoordinate ?? fallbackCoordinate)
        let destinationLocation = LocationInfo(address: destinationAddress, coordinate: destinationCoordinate ?? fallbackCoordinate)
        let hasDriver = (apiTrip.conductorId?.isEmpty == false)
            || (apiTrip.conductorNombre?.isEmpty == false)

        pickupText = pickupAddress
        destinationText = destinationAddress
        self.pickupCoordinate = pickupCoordinate
        self.destinationCoordinate = destinationCoordinate
        routePolyline = nil
        if let total = apiTrip.precioTotal {
            estimatedFare = formatFare(total)
        }
        if let distance = apiTrip.distanciaKm {
            estimatedDistance = String(format: "%.1f km", distance)
        }
        if let duration = apiTrip.duracion, !duration.isEmpty {
            estimatedDuration = duration
        }

        if let pickupCoordinate = pickupCoordinate, let destinationCoordinate = destinationCoordinate {
            updateMapRegionForRoute(pickup: pickupCoordinate, destination: destinationCoordinate)
            Task { @MainActor in
                if let route = try? await calculateRoute(from: pickupCoordinate, to: destinationCoordinate) {
                    routePolyline = route.polyline
                    estimatedDistance = String(format: "%.1f km", route.distance / 1000)
                    estimatedDuration = formatDuration(route.expectedTravelTime)
                }
            }
        } else if let pickupCoordinate = pickupCoordinate {
            updateMapRegion(to: pickupCoordinate)
        }

        let status = tripStatusFromAPI(apiTrip.estado, hasDriver: hasDriver)
        let paymentMethod = PaymentMethodInfo(
            type: paymentType(from: apiTrip.paymentMethod),
            displayName: apiTrip.paymentMethod
        )

        currentTrip = Trip(
            id: apiTrip.id,
            userId: AuthServiceAPI.shared.currentUser?.id ?? "user",
            status: status,
            pickupLocation: pickupLocation,
            destinationLocation: destinationLocation,
            estimatedFare: apiTrip.precioTotal ?? parseEstimatedFare(),
            estimatedDistance: apiTrip.distanciaKm ?? parseEstimatedDistance(),
            estimatedDuration: parseEstimatedDuration(),
            vehicleType: "Standard",
            paymentMethod: paymentMethod,
            createdAt: apiTrip.createdAt.toDate() ?? Date(),
            scheduledAt: apiTrip.fechaInicio.toDate() ?? requestedServiceDate
        )

        currentTripState = tripState(from: status, hasDriver: hasDriver)
        resumeTripMonitoringIfNeeded()

        if hasDriver {
            assignedDriver = buildAssignedDriver(
                driverId: apiTrip.conductorId,
                driverName: apiTrip.conductorNombre
            )
        }
    }

    private func handleDriverAssigned(driverId: String?, driverName: String?) {
        // Update with real driver information when assigned
        currentTripState = .driverAssigned
        currentTrip?.status = .driverAssigned
        print("✅ Conductor asignado para el viaje")

        let assigned = buildAssignedDriver(driverId: driverId, driverName: driverName)
        assignedDriver = assigned

        if shouldNotifyRideUpdates(), let trip = currentTrip {
            NotificationService.shared.scheduleDriverAssignedNotification(for: trip, driver: assigned)
        }
    }

    private func handleTripRejected(reason: String?) {
        currentTripState = .cancelled
        currentTrip?.status = .cancelled
        errorMessage = "El viaje fue cancelado o rechazado por el administrador"

        if shouldNotifyRideUpdates(), let trip = currentTrip {
            let message = reason == "RECHAZADO"
                ? "Tu viaje fue rechazado. Puedes solicitar otro cuando quieras."
                : "Tu viaje fue cancelado. Puedes solicitar otro cuando quieras."
            NotificationService.shared.scheduleTripCancelledNotification(for: trip, reason: message)
        }
    }

    private func shouldNotifyRideUpdates() -> Bool {
        guard let prefs = UserManager.shared.currentUser?.preferences.notifications else {
            return false
        }
        return prefs.pushNotifications && prefs.rideUpdates
    }

    private func buildAssignedDriver(driverId: String?, driverName: String?) -> Driver {
        let mockVehicle = VehicleInfo(
            make: "Tesla",
            model: "Model Y",
            year: 2023,
            color: "Blanco",
            licensePlate: "ABC1234",
            capacity: 4,
            vehicleType: .sedan
        )

        var assigned = Driver(
            userId: driverId ?? "driver123",
            licenseNumber: "ES123456789",
            name: driverName ?? "Conductor Asignado",
            vehicleInfo: mockVehicle
        )
        assigned.rating = 4.8
        assigned.totalTrips = 180
        assigned.estimatedArrival = 8 * 60
        assigned.isActive = true
        assigned.isOnline = true

        return assigned
    }

    private func coordinateFromAPI(lat: Double?, lng: Double?) -> CLLocationCoordinate2D? {
        guard let lat = lat, let lng = lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private func paymentType(from method: String?) -> PaymentType {
        switch method?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "APPLE_PAY":
            return .applePay
        case "CASH", "EFECTIVO":
            return .cash
        default:
            return .creditCard
        }
    }

    private func tripStatusFromAPI(_ estado: String, hasDriver: Bool) -> TripStatus {
        let normalized = estado.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        switch normalized {
        case "ACEPTADO", "ASSIGNED", "ASIGNADO":
            return .driverAssigned
        case "EN_CAMINO", "EN_RUTA", "EN_ROUTE":
            return .driverEnRoute
        case "LLEGADO", "ARRIVED":
            return .driverArrived
        case "EN_CURSO", "IN_PROGRESS", "EN_PROGRESO":
            return .inProgress
        case "COMPLETADO", "FINALIZADO":
            return .completed
        case "CANCELADO", "RECHAZADO", "EXPIRADO":
            return .cancelled
        case "PENDIENTE", "REQUESTED":
            return .requested
        default:
            return hasDriver ? .driverAssigned : .requested
        }
    }

    private func tripState(from status: TripStatus, hasDriver: Bool) -> TripState {
        switch status {
        case .driverAssigned:
            return .driverAssigned
        case .driverEnRoute:
            return .driverEnRoute
        case .driverArrived:
            return .driverArrived
        case .inProgress:
            return .inProgress
        case .completed:
            return .completed
        case .cancelled, .failed:
            return .cancelled
        case .requested:
            return hasDriver ? .driverAssigned : .findingDriver
        case .scheduled:
            return .readyToConfirm
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
            paymentMethod: paymentMethod,
            scheduledAt: requestedServiceDate
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

private struct ActiveTripSnapshot: Codable {
    let trip: Trip
    let driver: Driver?
}
