import SwiftUI
import MapKit
import Combine

struct TestInputView: View {
    @StateObject private var testModel = TestViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test de Inputs")
                .font(.title)
            
            VStack(spacing: 10) {
                TextField("Escribe algo aquí...", text: $testModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: testModel.searchText) { newValue in
                        print("🧪 Text changed to: '\(newValue)'")
                        testModel.updateSearch(newValue)
                    }
                
                Text("Texto actual: '\(testModel.searchText)'")
                    .font(.caption)
                
                Text("Sugerencias: \(testModel.suggestions.count)")
                    .font(.caption)
                
                if !testModel.suggestions.isEmpty {
                    VStack {
                        ForEach(Array(testModel.suggestions.prefix(5).enumerated()), id: \.offset) { index, suggestion in
                            HStack {
                                Text("\(index + 1). \(suggestion.title)")
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onTapGesture {
                                print("🧪 Selected: \(suggestion.title)")
                                testModel.searchText = suggestion.title
                                testModel.suggestions.removeAll()
                            }
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

@MainActor
final class TestViewModel: NSObject, ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        setupCompleter()
    }
    
    private func setupCompleter() {
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        print("🧪 Test completer setup complete")
    }
    
    func updateSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🧪 Updating search with: '\(trimmed)' (length: \(trimmed.count))")
        
        if trimmed.count >= 2 {
            completer.queryFragment = trimmed
            print("🧪 Set completer query: '\(trimmed)'")
        } else {
            suggestions.removeAll()
            print("🧪 Cleared suggestions - text too short")
        }
    }
}

extension TestViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
            print("🧪 Test completer got \(completer.results.count) results")
            for (i, result) in completer.results.prefix(3).enumerated() {
                print("🧪   \(i+1). \(result.title) - \(result.subtitle)")
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("🧪 Test completer error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.suggestions.removeAll()
        }
    }
}