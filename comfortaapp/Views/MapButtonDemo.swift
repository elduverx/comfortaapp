import SwiftUI
import MapKit
import CoreLocation

/// Vista de demostración del botón "Seleccionar en el mapa"
/// Usa esta vista para probar el botón y el selector de mapa
struct MapButtonDemo: View {
    @State private var destinationText = ""
    @State private var pickupText = "Valencia, España"
    @State private var showMapSelector = false
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var selectedAddress: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Ubicación de recogida") {
                    TextField("¿Dónde te recogemos?", text: $pickupText)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Destino") {
                    TextField("¿A dónde vas?", text: $destinationText)
                        .textFieldStyle(.roundedBorder)

                    // 🎯 BOTÓN DE SELECCIÓN EN EL MAPA
                    Button {
                        showMapSelector = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("Seleccionar en el mapa")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if let address = selectedAddress {
                    Section("Destino seleccionado") {
                        Label(address, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Demo del Botón de Mapa")
            .sheet(isPresented: $showMapSelector) {
                NavigationView {
                    MapDestinationPicker(
                        selectedDestination: $selectedDestination,
                        selectedAddress: $selectedAddress,
                        pickupLocation: CLLocationCoordinate2D(
                            latitude: 39.4699,
                            longitude: -0.3763
                        ),
                        pickupAddress: pickupText,
                        onDestinationConfirmed: { coordinate, address in
                            destinationText = address
                            selectedDestination = coordinate
                            selectedAddress = address
                            showMapSelector = false
                        }
                    )
                    .navigationTitle("Seleccionar destino")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cerrar") {
                                showMapSelector = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct MapButtonDemo_Previews: PreviewProvider {
    static var previews: some View {
        MapButtonDemo()
    }
}
