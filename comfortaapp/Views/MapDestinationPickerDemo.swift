import SwiftUI
import MapKit
import CoreLocation

/// Demo y ejemplo de uso del MapDestinationPicker
/// Muestra cómo integrar el selector de destino en tu app
struct MapDestinationPickerDemo: View {

    // MARK: - State
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var selectedAddress: String?
    @State private var pickupLocation = CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763)
    @State private var pickupAddress = "Plaza del Ayuntamiento, Valencia"
    @State private var showResults = false

    var body: some View {
        NavigationView {
            ZStack {
                // Mapa principal
                MapDestinationPicker(
                    selectedDestination: $selectedDestination,
                    selectedAddress: $selectedAddress,
                    pickupLocation: pickupLocation,
                    pickupAddress: pickupAddress,
                    onDestinationConfirmed: { coordinate, address in
                        handleDestinationConfirmed(coordinate: coordinate, address: address)
                    }
                )
                .ignoresSafeArea()

                // Results panel
                if showResults {
                    resultsPanel
                }
            }
            .navigationTitle("Seleccionar Destino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        resetDemo()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
        }
    }

    // MARK: - Results Panel

    private var resultsPanel: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)

                    Text("¡Destino Confirmado!")
                        .font(.title3.weight(.bold))

                    Spacer()

                    Button {
                        withAnimation {
                            showResults = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Pickup info
                InfoRow(
                    icon: "figure.walk.circle.fill",
                    iconColor: .green,
                    title: "Recogida",
                    subtitle: pickupAddress
                )

                // Destination info
                if let address = selectedAddress {
                    InfoRow(
                        icon: "flag.fill",
                        iconColor: .red,
                        title: "Destino",
                        subtitle: address
                    )
                }

                // Coordinates (for debugging)
                if let destination = selectedDestination {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coordenadas")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text("Lat: \(String(format: "%.6f", destination.latitude))")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("Lon: \(String(format: "%.6f", destination.longitude))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }

                // Action button
                Button {
                    proceedWithBooking()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Continuar con Reserva")
                    }
                    .font(.headline.weight(.bold))
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
                            .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    )
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
            )
            .padding(20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func handleDestinationConfirmed(coordinate: CLLocationCoordinate2D, address: String) {
        print("✅ Destino confirmado:")
        print("📍 Dirección: \(address)")
        print("📍 Coordenadas: \(coordinate.latitude), \(coordinate.longitude)")

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showResults = true
        }
    }

    private func proceedWithBooking() {
        print("🚀 Procediendo con la reserva...")
        print("📍 Pickup: \(pickupAddress)")
        if let address = selectedAddress {
            print("📍 Destination: \(address)")
        }

        // Aquí integrarías con tu sistema de reservas
        // Por ejemplo:
        // bookingViewModel.createBooking(
        //     pickup: pickupLocation,
        //     destination: selectedDestination!
        // )
    }

    private func resetDemo() {
        withAnimation {
            selectedDestination = nil
            selectedAddress = nil
            showResults = false
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.opacity(0.5))
        )
    }
}

// MARK: - Preview

struct MapDestinationPickerDemo_Previews: PreviewProvider {
    static var previews: some View {
        MapDestinationPickerDemo()
    }
}
