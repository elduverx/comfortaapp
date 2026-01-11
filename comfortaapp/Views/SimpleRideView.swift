import SwiftUI
import MapKit

struct SimpleRideView: View {
    @StateObject private var viewModel = SimpleRideViewModel()
    @FocusState private var isDestinationFieldFocused: Bool
    @FocusState private var isPickupFieldFocused: Bool
    @State private var showingRideFlow = false
    @State private var showingWizard = false
    let userName: String
    let onLogout: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map Background
            Map(coordinateRegion: $viewModel.mapRegion, 
                showsUserLocation: true,
                annotationItems: mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    MapPinView(type: annotation.type, title: annotation.title)
                }
            }
            .overlay(
                // Route overlay
                viewModel.routePolyline.map { polyline in
                    MapPolylineView(polyline: polyline)
                }
            )
            .ignoresSafeArea()
            .onTapGesture {
                viewModel.deactivateFields()
            }
            
            // Content Overlay
            VStack(spacing: 0) {
                headerView
                Spacer()
                bottomContentView
            }
            .padding()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .fullScreenCover(isPresented: $showingRideFlow) {
            RideFlowView(
                tripData: createTripData(),
                onComplete: {
                    showingRideFlow = false
                    viewModel.clearTrip()
                }
            )
        }
        .sheet(isPresented: $showingWizard) {
            WizardView()
        }
    }
    
    private var requestRideButton: some View {
        Button(action: {
            showingRideFlow = true
        }) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Pedir viaje")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text(viewModel.estimatedFare)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createTripData() -> TripData {
        TripData(
            pickupAddress: viewModel.pickupText,
            destinationAddress: viewModel.destinationText,
            pickupCoordinate: viewModel.pickupCoordinate!,
            destinationCoordinate: viewModel.destinationCoordinate!,
            estimatedFare: viewModel.estimatedFare,
            estimatedDistance: viewModel.estimatedDistance,
            estimatedDuration: viewModel.estimatedDuration,
            passengerName: userName
        )
    }
    
    private func clearTrip() {
        viewModel.pickupText = ""
        viewModel.destinationText = ""
        viewModel.pickupCoordinate = nil
        viewModel.destinationCoordinate = nil
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Comforta")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Hola, \(userName.isEmpty ? "Viajero" : userName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)
            
            Spacer()
            
            Button("Nueva reserva") {
                showingWizard = true
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .cornerRadius(8)
            
            Button("Cerrar sesión", action: onLogout)
                .font(.caption.weight(.medium))
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var bottomContentView: some View {
        VStack(spacing: 16) {
            // Search Fields
            VStack(spacing: 12) {
                // Pickup Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                        Text("Recogida")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button("Ubicación actual") {
                            viewModel.useCurrentLocation()
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.accentColor)
                    }
                    
                    TextField("¿Dónde te recogemos?", text: $viewModel.pickupText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isPickupFieldFocused)
                        .onTapGesture {
                            isPickupFieldFocused = true
                            viewModel.activatePickupField()
                        }
                        .onChange(of: isPickupFieldFocused) { isFocused in
                            if isFocused {
                                viewModel.activatePickupField()
                            }
                        }
                        .onChange(of: viewModel.pickupText) { newValue in
                            if !viewModel.isPickupFieldActive {
                                viewModel.activatePickupField()
                            }
                            viewModel.updatePickupText(newValue)
                        }
                    
                    
                    // Pickup Suggestions
                    if viewModel.isPickupFieldActive && !viewModel.pickupSuggestions.isEmpty {
                        suggestionsList(for: viewModel.pickupSuggestions, isPickup: true)
                    }
                }
                
                // Destination Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(.accentColor)
                        Text("Destino")
                            .font(.subheadline.weight(.medium))
                    }
                    
                    TextField("¿Dónde te llevamos?", text: $viewModel.destinationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isDestinationFieldFocused)
                        .onTapGesture {
                            isDestinationFieldFocused = true
                            viewModel.activateDestinationField()
                        }
                        .onChange(of: isDestinationFieldFocused) { isFocused in
                            if isFocused {
                                viewModel.activateDestinationField()
                            } else {
                                viewModel.deactivateFields()
                            }
                        }
                        .onChange(of: viewModel.destinationText) { newValue in
                            if !viewModel.isDestinationFieldActive {
                                viewModel.activateDestinationField()
                            }
                            viewModel.updateDestinationText(newValue)
                        }
                    
                    
                    // Destination Suggestions
                    if viewModel.isDestinationFieldActive && !viewModel.destinationSuggestions.isEmpty {
                        suggestionsList(for: viewModel.destinationSuggestions, isPickup: false)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Trip Summary
            tripSummaryView
                .padding(.horizontal, 20)
            
            // Request Ride Button
            if viewModel.pickupCoordinate != nil && viewModel.destinationCoordinate != nil {
                requestRideButton
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func suggestionsList(for suggestions: [MKLocalSearchCompletion], isPickup: Bool) -> some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(suggestions.prefix(5).enumerated()), id: \.offset) { index, suggestion in
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onTapGesture {
                    if isPickup {
                        viewModel.selectPickupSuggestion(suggestion)
                    } else {
                        viewModel.selectDestinationSuggestion(suggestion)
                    }
                    viewModel.deactivateFields()
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
        )
    }
    
    private var tripSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumen del viaje")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Precio estimado")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.estimatedFare)
                            .font(.title2.bold())
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    if !viewModel.estimatedDistance.isEmpty {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Distancia")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.estimatedDistance)
                                .font(.title3.weight(.semibold))
                        }
                    }
                }
                
                if !viewModel.estimatedDuration.isEmpty {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Duración estimada: \(viewModel.estimatedDuration)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color.clear
                .ultraLiquidGlass(cornerRadius: 16, intensity: 0.9)
        )
    }
    
    // MARK: - Map Components
    
    private var mapAnnotations: [SimpleMapAnnotationItem] {
        var annotations: [SimpleMapAnnotationItem] = []
        
        if let pickup = viewModel.pickupCoordinate {
            annotations.append(SimpleMapAnnotationItem(
                coordinate: pickup,
                type: .pickup,
                title: "Recogida"
            ))
        }
        
        if let destination = viewModel.destinationCoordinate {
            annotations.append(SimpleMapAnnotationItem(
                coordinate: destination,
                type: .destination,
                title: "Destino"
            ))
        }
        
        return annotations
    }
}

// MARK: - Map Annotation Item

private struct SimpleMapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: SimpleMapPinType
    let title: String
}

private enum SimpleMapPinType {
    case pickup
    case destination
}

private struct MapPinView: View {
    let type: SimpleMapPinType
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(type == .pickup ? Color.green : Color.accentColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: type == .pickup ? "mappin.circle.fill" : "flag.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
    }
}

private struct MapPolylineView: View {
    let polyline: MKPolyline
    
    var body: some View {
        // This is a placeholder - in a real implementation, 
        // you'd use a Map with overlays or a custom MapView
        EmptyView()
    }
}

struct SimpleRideView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleRideView(userName: "Juan Pérez", onLogout: {})
    }
}
