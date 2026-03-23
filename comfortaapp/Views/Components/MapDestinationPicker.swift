import SwiftUI
import MapKit
import CoreLocation

/// Selector de destino en mapa - Versión simplificada y funcional
/// Permite seleccionar ubicaciones tocando el mapa con feedback profesional
struct MapDestinationPicker: View {

    // MARK: - Bindings
    @Binding var selectedDestination: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?

    // MARK: - Properties
    let pickupLocation: CLLocationCoordinate2D
    let pickupAddress: String
    let onDestinationConfirmed: ((CLLocationCoordinate2D, String) -> Void)?

    // MARK: - State
    @State private var cameraPosition: MapCameraPosition
    @State private var isInSelectionMode = false
    @State private var tempLocation: CLLocationCoordinate2D?
    @State private var tempAddress: String?
    @State private var isLoading = false
    @State private var showInstructions = true

    @StateObject private var geocoder = ReverseGeocodingService.shared

    // MARK: - Initialization
    init(
        selectedDestination: Binding<CLLocationCoordinate2D?>,
        selectedAddress: Binding<String?>,
        pickupLocation: CLLocationCoordinate2D,
        pickupAddress: String,
        onDestinationConfirmed: ((CLLocationCoordinate2D, String) -> Void)? = nil
    ) {
        self._selectedDestination = selectedDestination
        self._selectedAddress = selectedAddress
        self.pickupLocation = pickupLocation
        self.pickupAddress = pickupAddress
        self.onDestinationConfirmed = onDestinationConfirmed

        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: pickupLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Mapa con MapReader para capturar taps
            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: .all) {
                    // Pin de recogida
                    Annotation("Recogida", coordinate: pickupLocation) {
                        PinView(
                            color: .green,
                            icon: "figure.walk.circle.fill",
                            label: "Recogida",
                            isSelected: false
                        )
                    }

                    // Pin temporal durante selección
                    if isInSelectionMode, let temp = tempLocation {
                        Annotation("Seleccionando", coordinate: temp) {
                            PinView(
                                color: .blue,
                                icon: "mappin.circle.fill",
                                label: tempAddress ?? "Cargando...",
                                isSelected: true
                            )
                        }
                    }

                    // Pin de destino confirmado
                    if let destination = selectedDestination {
                        Annotation("Destino", coordinate: destination) {
                            PinView(
                                color: .red,
                                icon: "flag.fill",
                                label: selectedAddress ?? "Destino",
                                isSelected: true
                            )
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                .onTapGesture { screenPosition in
                    // Solo permitir tap si no hay destino confirmado
                    guard selectedDestination == nil else { return }

                    // Convertir posición de pantalla a coordenadas del mapa
                    if let coordinate = proxy.convert(screenPosition, from: .local) {
                        handleMapTap(at: coordinate)
                    }
                }
            }

            // Instrucciones
            if showInstructions && selectedDestination == nil && !isInSelectionMode {
                instructionsCard
            }

            // Loading
            if isLoading {
                loadingIndicator
            }

            // Panel de confirmación
            if isInSelectionMode, let address = tempAddress {
                confirmationPanel(address: address)
            }

            // Info de destino confirmado
            if let address = selectedAddress {
                confirmedBanner(address: address)
            }
        }
        .onChange(of: cameraPosition) { oldValue, newValue in
            // Ocultar instrucciones al mover el mapa
            if showInstructions {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }

    // MARK: - Subviews

    private var instructionsCard: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)

                        Text("Toca el mapa")
                            .font(.subheadline.weight(.bold))
                    }

                    Text("Toca cualquier punto en el mapa para seleccionar tu destino")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
                .padding()

                Spacer()
            }
            .padding(.top, 60)

            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var loadingIndicator: some View {
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
                    .shadow(radius: 10)
            )
            .padding(.bottom, 200)
        }
        .transition(.opacity)
    }

    private func confirmationPanel(address: String) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                // Header
                Text("Confirmar Destino")
                    .font(.headline.weight(.bold))

                // Address
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Destino")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)

                        Text(address)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                )

                // Buttons
                HStack(spacing: 12) {
                    Button("Cancelar") {
                        cancelSelection()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background)
                    )

                    Button {
                        confirmSelection()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirmar")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .shadow(color: .blue.opacity(0.4), radius: 10)
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .padding(20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func confirmedBanner(address: String) -> some View {
        VStack {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino confirmado")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text(address)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        resetSelection()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.blue)
                    }
                }
                .padding(12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 10)
                )
                .padding()
            }
            .padding(.top, 60)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Actions

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // Solo permitir si no hay destino confirmado
        guard selectedDestination == nil else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tempLocation = coordinate
            isInSelectionMode = true
            isLoading = true
            showInstructions = false
        }

        Task {
            do {
                let address = try await geocoder.reverseGeocode(coordinate: coordinate)

                await MainActor.run {
                    withAnimation {
                        tempAddress = address
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        tempAddress = "Ubicación desconocida"
                        isLoading = false
                    }
                }
            }
        }
    }

    private func confirmSelection() {
        guard let location = tempLocation, let address = tempAddress else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedDestination = location
            selectedAddress = address
            isInSelectionMode = false
        }

        onDestinationConfirmed?(location, address)

        // Ajustar vista para mostrar ambos pins
        let region = MKCoordinateRegion.regionToFit(
            coordinates: [pickupLocation, location],
            paddingFactor: 1.5,
            minimumSpan: 0.01
        )

        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(region)
        }
    }

    private func cancelSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tempLocation = nil
            tempAddress = nil
            isInSelectionMode = false
            isLoading = false
        }
    }

    private func resetSelection() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedDestination = nil
            selectedAddress = nil
            tempLocation = nil
            tempAddress = nil
            isInSelectionMode = false
            showInstructions = true
        }
    }
}

// MARK: - Pin View

private struct PinView: View {
    let color: Color
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: isSelected ? 36 : 32, height: isSelected ? 36 : 32)
                    .shadow(color: color.opacity(0.5), radius: 8)

                Circle()
                    .fill(.white)
                    .frame(width: isSelected ? 30 : 26, height: isSelected ? 30 : 26)

                Image(systemName: icon)
                    .font(.system(size: isSelected ? 16 : 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 4)
                )
        }
    }
}

// MARK: - Preview

struct MapDestinationPicker_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContainer()
    }

    struct PreviewContainer: View {
        @State private var destination: CLLocationCoordinate2D?
        @State private var address: String?

        var body: some View {
            MapDestinationPicker(
                selectedDestination: $destination,
                selectedAddress: $address,
                pickupLocation: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
                pickupAddress: "Plaza del Ayuntamiento, Valencia",
                onDestinationConfirmed: { coord, addr in
                    print("✅ Destino: \(addr)")
                }
            )
        }
    }
}
