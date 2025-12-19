import SwiftUI
import MapKit

struct RideBookingView: View {
    @StateObject private var viewModel = RideBookingViewModel()
    @State private var showingSettings = false
    
    let userName: String
    let onLogout: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Map Background
                MapViewWrapper(
                    region: $viewModel.mapRegion,
                    trip: viewModel.currentTrip,
                    currentLocation: viewModel.locationManager.currentLocation
                )
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.clearSearch()
                }
                
                // Content Overlay
                VStack(spacing: 0) {
                    headerView
                    
                    Spacer()
                    
                    bottomContentView
                }
                .padding()
            }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(onLogout: onLogout)
        }
        .onAppear {
            viewModel.requestCurrentLocation()
        }
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
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
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
                LocationSearchField(
                    fieldType: .pickup,
                    text: $viewModel.pickupText,
                    isActive: viewModel.activeField == .pickup,
                    onTap: {
                        viewModel.setActiveField(.pickup)
                    },
                    onTextChange: { text in
                        viewModel.updateSearchText(for: .pickup, text: text)
                    }
                )
                
                LocationSearchField(
                    fieldType: .destination,
                    text: $viewModel.destinationText,
                    isActive: viewModel.activeField == .destination,
                    onTap: {
                        viewModel.setActiveField(.destination)
                    },
                    onTextChange: { text in
                        viewModel.updateSearchText(for: .destination, text: text)
                    }
                )
            }
            .padding(.horizontal, 20)
            
            // Search Suggestions
            if viewModel.activeField != nil && (!viewModel.searchSuggestions.isEmpty || viewModel.isSearching) {
                SearchSuggestionsList(
                    suggestions: viewModel.searchSuggestions,
                    isSearching: viewModel.isSearching,
                    onSuggestionSelected: { suggestion in
                        viewModel.selectSuggestion(suggestion)
                    }
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Trip Summary or Location Error
            if viewModel.isLocationPermissionDenied {
                LocationPermissionCard {
                    viewModel.requestLocationPermission()
                }
                .padding(.horizontal, 20)
            } else {
                TripSummaryCard(
                    trip: viewModel.currentTrip,
                    onCurrentLocationTapped: {
                        viewModel.useCurrentLocationAsPickup()
                    }
                )
                .padding(.horizontal, 20)
            }
            
            // Book Ride Button
            if viewModel.hasValidTrip {
                BookRideButton(
                    isEnabled: viewModel.currentTrip != nil,
                    onTap: {
                        if viewModel.confirmTrip() {
                            // Handle successful booking
                            print("Trip booked successfully!")
                        }
                    }
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.activeField != nil)
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasValidTrip)
    }
}

private struct LocationPermissionCard: View {
    let onRequestPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.orange)
            
            Text("Permisos de ubicación requeridos")
                .font(.headline.weight(.semibold))
            
            Text("Para ofrecerte el mejor servicio, necesitamos acceso a tu ubicación para encontrar conductores cerca de ti.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Activar ubicación", action: onRequestPermission)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

private struct BookRideButton: View {
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Reservar viaje")
                    .font(.headline.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled ? Color.accentColor : Color.gray)
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

private struct SettingsView: View {
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Button("Cerrar sesión") {
                    onLogout()
                    dismiss()
                }
                .foregroundColor(.red)
                .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RideBookingView_Previews: PreviewProvider {
    static var previews: some View {
        RideBookingView(
            userName: "Juan Pérez",
            onLogout: {}
        )
    }
}