import SwiftUI
import MapKit
import Combine

struct AddressSearchField: View {
    @Binding var selectedAddress: String
    @State private var searchText: String = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var isSearching = false
    
    @StateObject private var searchCompleter = SearchCompleter()
    
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Campo de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { oldValue, newValue in
                        searchCompleter.search(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        selectedAddress = ""
                        searchCompleter.cancel()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Resultados de búsqueda
            if !searchCompleter.results.isEmpty && !searchText.isEmpty {
                List(searchCompleter.results, id: \.self) { result in
                    Button(action: {
                        selectAddress(result)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .listStyle(.plain)
                .cornerRadius(10)
            }
        }
    }
    
    private func selectAddress(_ completion: MKLocalSearchCompletion) {
        // Crear búsqueda completa para obtener coordenadas
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        Task {
            do {
                let response = try await search.start()
                if !response.mapItems.isEmpty {
                    let fullAddress = [
                        completion.title,
                        completion.subtitle
                    ].joined(separator: ", ")
                    
                    await MainActor.run {
                        selectedAddress = fullAddress
                        searchText = completion.title
                        searchCompleter.cancel()
                    }
                }
            } catch {
                print("Error en búsqueda: \(error)")
            }
        }
    }
}

// MARK: - SearchCompleter

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        
        // Limitar búsqueda a España (Valencia)
        let valenciaRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
        completer.region = valenciaRegion
    }
    
    func search(query: String) {
        completer.queryFragment = query
    }
    
    func cancel() {
        completer.cancel()
        results = []
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.results = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error en autocompletado: \(error)")
        DispatchQueue.main.async { [weak self] in
            self?.results = []
        }
    }
}
