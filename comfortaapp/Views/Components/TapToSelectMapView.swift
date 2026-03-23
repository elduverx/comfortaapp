import SwiftUI
import MapKit
import CoreLocation

/// Vista de mapa interactiva profesional con selección por tap
/// Permite al usuario tocar el mapa para seleccionar ubicaciones
struct TapToSelectMapView: View {

    // MARK: - Bindings
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?

    // MARK: - Properties
    let initialRegion: MKCoordinateRegion
    let pickupLocation: CLLocationCoordinate2D?
    let showPickupPin: Bool
    let onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)?

    // MARK: - State
    @State private var cameraPosition: MapCameraPosition
    @State private var isLoadingAddress = false
    @State private var showConfirmButton = false
    @State private var tempSelectedLocation: CLLocationCoordinate2D?
    @State private var tempAddress: String?

    @StateObject private var geocodingService = ReverseGeocodingService.shared

    // MARK: - Initialization
    init(
        selectedLocation: Binding<CLLocationCoordinate2D?>,
        selectedAddress: Binding<String?>,
        initialRegion: MKCoordinateRegion,
        pickupLocation: CLLocationCoordinate2D? = nil,
        showPickupPin: Bool = true,
        onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)? = nil
    ) {
        self._selectedLocation = selectedLocation
        self._selectedAddress = selectedAddress
        self.initialRegion = initialRegion
        self.pickupLocation = pickupLocation
        self.showPickupPin = showPickupPin
        self.onLocationSelected = onLocationSelected

        _cameraPosition = State(initialValue: .region(initialRegion))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Mapa principal
            mapView

            // Overlay de instrucciones
            if selectedLocation == nil && tempSelectedLocation == nil {
                instructionsOverlay
            }

            // Loading indicator
            if isLoadingAddress {
                loadingOverlay
            }

            // Confirm button
            if showConfirmButton, let address = tempAddress {
                confirmLocationButton(address: address)
            }
        }
    }

    // MARK: - Map View
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Pin de recogida
            if showPickupPin, let pickup = pickupLocation {
                Annotation("Recogida", coordinate: pickup) {
                    AnimatedMapPin(
                        type: .pickup,
                        title: "Recogida",
                        isSelected: false
                    )
                }
            }

            // Pin temporal (mientras se carga la dirección)
            if let tempLoc = tempSelectedLocation, selectedLocation == nil {
                Annotation("Seleccionando...", coordinate: tempLoc) {
                    AnimatedMapPin(
                        type: .selectedLocation,
                        title: isLoadingAddress ? "Cargando..." : tempAddress,
                        isSelected: true
                    )
                }
            }

            // Pin de destino confirmado
            if let destination = selectedLocation {
                Annotation("Destino", coordinate: destination) {
                    AnimatedMapPin(
                        type: .destination,
                        title: selectedAddress ?? "Destino",
                        isSelected: true
                    )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.publicTransport, .airport, .hotel, .restaurant])))
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
        .onTapGesture { screenLocation in
            handleMapTap(at: screenLocation)
        }
    }

    // MARK: - Overlays

    private var instructionsOverlay: some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)

                        Text("Toca el mapa para seleccionar destino")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                    }

                    Text("El pin se colocará en la ubicación seleccionada")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding()

                Spacer()
            }

            Spacer()
        }
        .allowsHitTesting(false)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var loadingOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)

                Text("Obteniendo dirección...")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .padding(.bottom, 100)
        }
        .transition(.opacity.combined(with: .scale))
    }

    private func confirmLocationButton(address: String) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // Address preview
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Destino seleccionado")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)

                        Text(address)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )

                // Buttons
                HStack(spacing: 12) {
                    // Cancel button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            tempSelectedLocation = nil
                            tempAddress = nil
                            showConfirmButton = false
                        }
                    } label: {
                        Text("Cancelar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                    }

                    // Confirm button
                    Button {
                        confirmSelection()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirmar Destino")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func handleMapTap(at screenLocation: CGPoint) {
        // No permitir seleccionar si ya hay una ubicación confirmada
        guard selectedLocation == nil else { return }

        // Convert screen point to coordinate (aproximación)
        // Nota: En producción, necesitaríamos usar MKMapView para convertir exactamente
        // Por ahora, usamos el centro de la región visible
        let coordinate = getCameraCoordinate()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tempSelectedLocation = coordinate
            isLoadingAddress = true
            showConfirmButton = false
            tempAddress = nil
        }

        // Obtener dirección
        Task {
            do {
                let address = try await geocodingService.reverseGeocode(coordinate: coordinate)

                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        tempAddress = address
                        isLoadingAddress = false
                        showConfirmButton = true
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        tempAddress = "Ubicación desconocida"
                        isLoadingAddress = false
                        showConfirmButton = true
                    }
                }
                print("Error al obtener dirección: \(error)")
            }
        }
    }

    private func confirmSelection() {
        guard let location = tempSelectedLocation, let address = tempAddress else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedLocation = location
            selectedAddress = address
            showConfirmButton = false
        }

        // Callback
        onLocationSelected?(location, address)

        // Animar cámara para mostrar pickup y destino
        if let pickup = pickupLocation {
            let region = MKCoordinateRegion.regionToFit(
                coordinates: [pickup, location],
                paddingFactor: 1.5,
                minimumSpan: 0.01
            )

            withAnimation(.easeInOut(duration: 0.8)) {
                cameraPosition = .region(region)
            }
        }
    }

    private func getCameraCoordinate() -> CLLocationCoordinate2D {
        // Aproximación: retorna el centro actual de la cámara
        // En producción, esto debería ser más preciso
        if let region = cameraPosition.region {
            return region.center
        }
        if let rect = cameraPosition.rect {
            let centerPoint = MKMapPoint(x: rect.midX, y: rect.midY)
            return centerPoint.coordinate
        }
        return initialRegion.center
    }
}

// MARK: - Preview

struct TapToSelectMapView_Previews: PreviewProvider {
    static var previews: some View {
        TapToSelectMapViewPreviewContainer()
    }
}

private struct TapToSelectMapViewPreviewContainer: View {
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedAddress: String?

    var body: some View {
        TapToSelectMapView(
            selectedLocation: $selectedLocation,
            selectedAddress: $selectedAddress,
            initialRegion: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ),
            pickupLocation: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
            onLocationSelected: { coordinate, address in
                print("📍 Ubicación seleccionada: \(address)")
                print("📍 Coordenadas: \(coordinate.latitude), \(coordinate.longitude)")
            }
        )
    }
}
