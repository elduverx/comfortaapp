import SwiftUI
import MapKit

struct RideFlowView: View {
    @StateObject private var viewModel: RideFlowViewModel
    let onComplete: () -> Void
    
    init(tripData: TripData, onComplete: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: RideFlowViewModel(tripData: tripData))
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map Background
                Map(coordinateRegion: $viewModel.mapRegion, 
                    showsUserLocation: true,
                    annotationItems: viewModel.mapAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        RideMapPin(type: annotation.type, title: annotation.title)
                    }
                }
                .ignoresSafeArea()
                
                // Content Overlay
                VStack {
                    Spacer()
                    
                    switch viewModel.currentStatus {
                    case .requested:
                        RequestingView(tripData: viewModel.tripData)
                    case .driverAssigned, .driverEnRoute:
                        DriverEnRouteView(
                            tripData: viewModel.tripData,
                            driver: viewModel.assignedDriver!,
                            status: viewModel.currentStatus
                        )
                    case .driverArrived:
                        DriverArrivedView(
                            tripData: viewModel.tripData,
                            driver: viewModel.assignedDriver!
                        )
                    case .inProgress:
                        TripInProgressView(
                            tripData: viewModel.tripData,
                            driver: viewModel.assignedDriver!
                        )
                    case .completed:
                        TripCompletedView(
                            tripData: viewModel.tripData,
                            driver: viewModel.assignedDriver!,
                            onComplete: onComplete
                        )
                    case .cancelled:
                        TripCancelledView(onComplete: onComplete)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        viewModel.cancelTrip()
                    }
                    .foregroundColor(.red)
                    .disabled(viewModel.currentStatus == .inProgress || viewModel.currentStatus == .completed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ayuda") {
                        viewModel.showHelp()
                    }
                }
            }
        }
        .onAppear {
            viewModel.startTripFlow()
        }
        .alert("Viaje Cancelado", isPresented: $viewModel.showingCancellationAlert) {
            Button("OK") {
                onComplete()
            }
        } message: {
            Text("Tu viaje ha sido cancelado. No se realizará ningún cargo.")
        }
    }
}

// MARK: - Map Annotations

struct RideMapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: RideMapPinType
    let title: String
}

enum RideMapPinType {
    case pickup
    case destination
    case driver
}

struct RideMapPin: View {
    let type: RideMapPinType
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: pinIcon)
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
    
    private var pinColor: Color {
        switch type {
        case .pickup:
            return .green
        case .destination:
            return .accentColor
        case .driver:
            return .orange
        }
    }
    
    private var pinIcon: String {
        switch type {
        case .pickup:
            return "mappin.circle.fill"
        case .destination:
            return "flag.fill"
        case .driver:
            return "car.fill"
        }
    }
}

// MARK: - Requesting View

struct RequestingView: View {
    let tripData: TripData
    
    var body: some View {
        VStack(spacing: 20) {
            // Loading Animation
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: true
                        )
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 12) {
                Text("Buscando conductor")
                    .font(.title2.bold())
                
                Text("Estamos conectándote con un conductor cercano")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Trip Details Summary
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recogida")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.pickupAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.destinationAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Precio estimado")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.estimatedFare)
                            .font(.headline.bold())
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Tiempo estimado")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.estimatedDuration)
                            .font(.headline.weight(.semibold))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    RideFlowView(
        tripData: TripData(
            pickupAddress: "Calle Ejemplo 123, Madrid",
            destinationAddress: "Plaza Mayor, Madrid",
            pickupCoordinate: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            destinationCoordinate: CLLocationCoordinate2D(latitude: 40.4155, longitude: -3.7074),
            estimatedFare: "€12.50",
            estimatedDistance: "3.2 km",
            estimatedDuration: "8 min",
            passengerName: "Juan Pérez"
        ),
        onComplete: {}
    )
}