import Foundation
import Combine
import MapKit
import CoreLocation
import SwiftUI

// MARK: - SearchService Implementation
final class SearchServiceImpl: NSObject, ObservableObject {
    @Published var suggestions: [SearchSuggestion] = []
    @Published var isSearching: Bool = false
    
    private let completer = MKLocalSearchCompleter()
    private let geocodingService = GeocodingService()
    private var searchTask: Task<Void, Never>?
    
    override init() {
        super.init()
        setupCompleter()
    }
    
    private func setupCompleter() {
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.filterType = .locationsOnly
    }
    
    func search(query: String, in region: MKCoordinateRegion) {
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only log non-empty queries to reduce console noise
        if !trimmedQuery.isEmpty {
            print("🔍 Searching for: '\(trimmedQuery)'")
        }
        
        guard !trimmedQuery.isEmpty else {
            // Silently clear results for empty queries
            clearResults()
            return
        }
        
        guard trimmedQuery.count >= 2 else {
            if trimmedQuery.count > 0 {
                print("❌ Query too short: \(trimmedQuery.count) characters")
            }
            clearResults()
            return
        }
        
        // Avoid duplicate searches
        if completer.queryFragment == trimmedQuery {
            print("⏭️ Skipping duplicate search for: '\(trimmedQuery)'")
            return
        }
        
        searchTask = Task { @MainActor in
            print("🟡 Starting search for: '\(trimmedQuery)'")
            isSearching = true
            completer.region = region
            completer.queryFragment = trimmedQuery
        }
    }
    
    func resolveSuggestion(_ suggestion: SearchSuggestion) async throws -> LocationPoint {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        let search = MKLocalSearch(request: request)
        
        let response = try await search.start()
        
        guard let mapItem = response.mapItems.first else {
            throw NSError(domain: "SearchError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No results"])
        }
        
        let coordinate = mapItem.placemark.coordinate
        let address = suggestion.fullAddress
        let name = mapItem.name
        
        return LocationPoint(
            coordinate: coordinate,
            address: address,
            name: name
        )
    }
    
    func clearResults() {
        searchTask?.cancel()
        
        // Only update if there are changes to avoid unnecessary publishing
        if !suggestions.isEmpty {
            suggestions.removeAll()
        }
        
        if !completer.queryFragment.isEmpty {
            completer.queryFragment = ""
        }
        
        if isSearching {
            isSearching = false
        }
    }
}

extension SearchServiceImpl: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("✅ Completer got \(completer.results.count) results")
        DispatchQueue.main.async {
            self.suggestions = completer.results.map(SearchSuggestion.init)
            self.isSearching = false
            print("📱 Updated UI with \(self.suggestions.count) suggestions")
            for (index, suggestion) in self.suggestions.prefix(3).enumerated() {
                print("  \(index + 1). \(suggestion.title) - \(suggestion.subtitle)")
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Search error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.suggestions = []
            self.isSearching = false
        }
    }
}

@MainActor
final class RideBookingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var pickupText: String = ""
    @Published var destinationText: String = ""
    @Published var activeField: SearchFieldType?
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var isSearching: Bool = false
    @Published var currentTrip: Trip?
    @Published var errorMessage: String?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    // MARK: - Private Properties
    private var pickupLocation: LocationPoint?
    private var destinationLocation: LocationPoint?
    let locationManager = LocationManager()
    private var searchService: SearchServiceImpl
    private let tripService = TripCalculationService()
    private let geocodingService = GeocodingService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var hasValidTrip: Bool {
        pickupLocation != nil && destinationLocation != nil
    }
    
    var formattedFare: String {
        guard let trip = currentTrip else {
            return "Selecciona recogida y destino"
        }
        return trip.formattedFare
    }
    
    var formattedDistance: String {
        guard let trip = currentTrip else { return "" }
        return trip.formattedDistance
    }
    
    var formattedDuration: String {
        guard let trip = currentTrip else { return "" }
        return trip.formattedDuration
    }
    
    var isLocationPermissionDenied: Bool {
        locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted
    }
    
    // MARK: - Initialization
    init() {
        searchService = SearchServiceImpl()
        setupBindings()
        requestLocationPermission()
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    func requestCurrentLocation() {
        locationManager.requestLocation()
    }
    
    func setActiveField(_ field: SearchFieldType) {
        activeField = field
        updateSearchQuery()
    }
    
    func updateSearchText(for field: SearchFieldType, text: String) {
        // Only update if text actually changed
        let currentText: String
        switch field {
        case .pickup:
            currentText = pickupText
            pickupText = text
        case .destination:
            currentText = destinationText
            destinationText = text
        }
        
        // Only trigger search if field is active and text changed
        if activeField == field && currentText != text {
            updateSearchQuery()
        }
    }
    
    func selectSuggestion(_ suggestion: SearchSuggestion) {
        Task {
            do {
                let location = try await searchService.resolveSuggestion(suggestion)
                
                switch activeField {
                case .pickup:
                    pickupLocation = location
                    pickupText = location.address
                case .destination:
                    destinationLocation = location
                    destinationText = location.address
                case .none:
                    return
                }
                
                clearSearch()
                updateMapRegion(to: location.coordinate)
                await calculateTripIfReady()
                
            } catch {
                errorMessage = "Error al seleccionar ubicación: \(error.localizedDescription)"
            }
        }
    }
    
    func useCurrentLocationAsPickup() {
        Task {
            guard let currentLocation = locationManager.currentLocation else {
                errorMessage = "No se pudo obtener la ubicación actual"
                return
            }
            
            do {
                let address = try await geocodingService.reverseGeocode(currentLocation)
                let locationPoint = LocationPoint(
                    coordinate: currentLocation.coordinate,
                    address: address,
                    name: "Ubicación actual"
                )
                
                pickupLocation = locationPoint
                pickupText = "Ubicación actual"
                updateMapRegion(to: currentLocation.coordinate)
                await calculateTripIfReady()
                
            } catch {
                errorMessage = "Error al obtener dirección actual: \(error.localizedDescription)"
            }
        }
    }
    
    func clearSearch() {
        activeField = nil
        searchService.clearResults()
    }
    
    func clearTrip() {
        pickupLocation = nil
        destinationLocation = nil
        pickupText = ""
        destinationText = ""
        currentTrip = nil
        clearSearch()
        errorMessage = nil
    }
    
    func confirmTrip() -> Bool {
        guard hasValidTrip, let trip = currentTrip else {
            errorMessage = "Completa la información del viaje"
            return false
        }
        
        // Here you would typically save the trip or send it to a booking service
        print("Trip confirmed: \(trip)")
        return true
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Bind location updates
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateMapRegion(to: location.coordinate)
                
                // Auto-set pickup if empty and we have location
                if self?.pickupText.isEmpty == true && self?.pickupLocation == nil {
                    Task {
                        await self?.useCurrentLocationAsPickup()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Bind location errors
        locationManager.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        // Bind search results
        searchService.$suggestions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] suggestions in
                print("🔗 ViewModel received \(suggestions.count) suggestions")
                self?.searchSuggestions = suggestions
            }
            .store(in: &cancellables)
        
        // Bind search state
        searchService.$isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearching in
                self?.isSearching = isSearching
            }
            .store(in: &cancellables)
    }
    
    private func updateSearchQuery() {
        guard let activeField = activeField else { 
            print("❌ No active field")
            return 
        }
        
        let query: String
        switch activeField {
        case .pickup:
            query = pickupText
        case .destination:
            query = destinationText
        }
        
        print("🎯 updateSearchQuery: field=\(activeField), query='\(query)'")
        searchService.search(query: query, in: mapRegion)
    }
    
    private func updateMapRegion(to coordinate: CLLocationCoordinate2D) {
        mapRegion.center = coordinate
        
        // Update search region for better results
        searchService.search(query: getCurrentSearchQuery(), in: mapRegion)
    }
    
    private func getCurrentSearchQuery() -> String {
        guard let activeField = activeField else { return "" }
        
        switch activeField {
        case .pickup:
            return pickupText
        case .destination:
            return destinationText
        }
    }
    
    private func calculateTripIfReady() async {
        guard let pickup = pickupLocation,
              let destination = destinationLocation else {
            currentTrip = nil
            return
        }
        
        do {
            let trip = try await tripService.calculateTrip(from: pickup, to: destination)
            currentTrip = trip
            errorMessage = nil
        } catch {
            errorMessage = "Error al calcular el viaje: \(error.localizedDescription)"
            currentTrip = nil
        }
    }
}
