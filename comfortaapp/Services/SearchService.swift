import Foundation
import Combine
import MapKit

public final class SearchService: NSObject, ObservableObject {
    @Published var suggestions: [SearchSuggestion] = []
    @Published var isSearching: Bool = false
    
    private let completer = MKLocalSearchCompleter()
    private let geocodingService: GeocodingService
    private var searchTask: Task<Void, Never>?
    
    public init(geocodingService: GeocodingService = GeocodingService()) {
        self.geocodingService = geocodingService
        super.init()
        setupCompleter()
    }
    
    private func setupCompleter() {
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.filterType = .locationsOnly
    }
    
    public func search(query: String, in region: MKCoordinateRegion) {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearResults()
            return
        }
        
        searchTask = Task { @MainActor in
            isSearching = true
            completer.region = region
            completer.queryFragment = query
            
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            if !Task.isCancelled {
                isSearching = false
            }
        }
    }
    
    public func resolveSuggestion(_ suggestion: SearchSuggestion) async throws -> LocationPoint {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        let search = MKLocalSearch(request: request)
        
        let response = try await search.start()
        
        guard let mapItem = response.mapItems.first else {
            throw SearchError.noResults
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
    
    public func clearResults() {
        searchTask?.cancel()
        suggestions.removeAll()
        completer.queryFragment = ""
        isSearching = false
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension SearchService: MKLocalSearchCompleterDelegate {
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results.map(SearchSuggestion.init)
            self.isSearching = false
        }
    }
    
    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
            self.isSearching = false
            print("Search error: \(error.localizedDescription)")
        }
    }
}

enum SearchError: LocalizedError {
    case noResults
    case networkError
    case invalidQuery
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No se encontraron resultados"
        case .networkError:
            return "Error de red"
        case .invalidQuery:
            return "Consulta de búsqueda inválida"
        }
    }
}