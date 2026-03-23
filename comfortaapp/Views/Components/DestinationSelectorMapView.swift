import SwiftUI
import MapKit
import CoreLocation
import UIKit

/// Vista completa profesional de selección de destino en el mapa
/// Combina todos los componentes para una experiencia de usuario excepcional
struct DestinationSelectorMapView: View {

    // MARK: - Bindings
    @Binding var selectedDestination: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?

    // MARK: - Properties
    let pickupLocation: CLLocationCoordinate2D
    let pickupAddress: String
    let onDestinationConfirmed: ((CLLocationCoordinate2D, String) -> Void)?

    // MARK: - State
    @State private var tempSelectedLocation: CLLocationCoordinate2D?
    @State private var tempAddress: String?
    @State private var isLoadingAddress = false
    @State private var showConfirmation = false
    @State private var mapRegion: MKCoordinateRegion

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

        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: pickupLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Mapa interactivo
            InteractiveTapMapView(
                selectedCoordinate: $tempSelectedLocation,
                selectedAddress: $tempAddress,
                region: mapRegion,
                pickupLocation: pickupLocation,
                showPickupPin: true,
                onLocationSelected: { coordinate in
                    handleLocationTapped(coordinate: coordinate)
                }
            )
            .ignoresSafeArea(edges: .all)

            // Overlay de instrucciones
            if tempSelectedLocation == nil && selectedDestination == nil {
                instructionsOverlay
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Loading overlay
            if isLoadingAddress {
                loadingOverlay
                    .transition(.opacity.combined(with: .scale))
            }

            // Confirmation panel
            if showConfirmation, let address = tempAddress {
                confirmationPanel(address: address)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Confirmed destination info
            if let destination = selectedDestination, let address = selectedAddress {
                confirmedDestinationInfo(address: address)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: tempSelectedLocation)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showConfirmation)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLoadingAddress)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDestination)
    }

    // MARK: - Overlays

    private var instructionsOverlay: some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Toca el mapa")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.primary)
                    }

                    Text("Selecciona tu destino tocando cualquier punto en el mapa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()
            }

            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var loadingOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.1)

                Text("Obteniendo dirección...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(.black.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
            )
            .padding(.bottom, 120)
        }
    }

    private func confirmationPanel(address: String) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirmar Destino")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.primary)

                        Text("Verifica que la ubicación sea correcta")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Address card
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Destino seleccionado")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(address)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 2)
                )

                // Action buttons
                HStack(spacing: 12) {
                    // Cancel
                    Button {
                        cancelSelection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                            Text("Cancelar")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                    }

                    // Confirm
                    Button {
                        confirmSelection()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Confirmar")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private func confirmedDestinationInfo(address: String) -> some View {
        VStack {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino confirmado")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text(address)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()
            }

            Spacer()
        }
        .allowsHitTesting(true)
    }

    // MARK: - Actions

    private func handleLocationTapped(coordinate: CLLocationCoordinate2D) {
        // Prevenir selección si ya hay destino confirmado
        guard selectedDestination == nil else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLoadingAddress = true
            showConfirmation = false
        }

        // Feedback háptico
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Obtener dirección (esto se maneja en InteractiveTapMapView)
        // Esperar un momento para que se cargue la dirección
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isLoadingAddress = false
                showConfirmation = true
            }
        }
    }

    private func confirmSelection() {
        guard let location = tempSelectedLocation, let address = tempAddress else { return }

        // Feedback háptico
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedDestination = location
            selectedAddress = address
            showConfirmation = false
        }

        // Callback
        onDestinationConfirmed?(location, address)
    }

    private func cancelSelection() {
        // Feedback háptico
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tempSelectedLocation = nil
            tempAddress = nil
            showConfirmation = false
        }
    }

    private func resetSelection() {
        // Feedback háptico
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedDestination = nil
            selectedAddress = nil
            tempSelectedLocation = nil
            tempAddress = nil
            showConfirmation = false
        }
    }
}

// MARK: - Preview

struct DestinationSelectorMapView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationSelectorMapViewPreviewContainer()
    }
}

private struct DestinationSelectorMapViewPreviewContainer: View {
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var selectedAddress: String?

    var body: some View {
        DestinationSelectorMapView(
            selectedDestination: $selectedDestination,
            selectedAddress: $selectedAddress,
            pickupLocation: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
            pickupAddress: "Plaza del Ayuntamiento, Valencia",
            onDestinationConfirmed: { coordinate, address in
                print("✅ Destino confirmado:")
                print("📍 Dirección: \(address)")
                print("📍 Coordenadas: \(coordinate.latitude), \(coordinate.longitude)")
            }
        )
    }
}
