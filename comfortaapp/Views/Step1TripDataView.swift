import SwiftUI
import Combine
import CoreLocation
import MapKit

struct Step1TripDataView: View {
    @ObservedObject var viewModel: WizardViewModel
    @StateObject private var locationService = LocationService()
    @State private var showMapSelector = false
    @State private var selectedDestinationCoord: CLLocationCoordinate2D?
    @State private var selectedDestinationAddress: String?

    var body: some View {
        Form {
            Section {
                // Usar ubicación actual
                Button(action: { useCurrentLocation() }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Usar mi ubicación actual")
                    }
                }
                .disabled(locationService.authorizationStatus != .authorizedWhenInUse)
            }
            
            Section("¿Dónde te recogemos?") {
                AddressSearchField(
                    selectedAddress: $viewModel.lugarRecogida,
                    placeholder: "Dirección de recogida"
                )
            }
            
            Section("¿A dónde vamos?") {
                AddressSearchField(
                    selectedAddress: $viewModel.destino,
                    placeholder: "Dirección de destino"
                )

                // Botón para seleccionar en el mapa
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
            
            Section("¿Cuándo?") {
                DatePicker(
                    "Fecha y hora",
                    selection: $viewModel.fechaInicio,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                
                Picker("Franja horaria", selection: $viewModel.franjaHoraria) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Text(slot).tag(slot)
                    }
                }
            }
            
            // Vista previa del mapa
            if !viewModel.lugarRecogida.isEmpty && !viewModel.destino.isEmpty {
                Section("Vista previa") {
                    MapPreviewView(
                        origin: viewModel.lugarRecogida,
                        destination: viewModel.destino
                    )
                    .frame(height: 200)
                    .cornerRadius(12)
                }
            }
            
            Button("Continuar") {
                viewModel.currentStep = 2
            }
            .disabled(!viewModel.isStep1Valid)
        }
        .navigationTitle("Datos del viaje")
        .onAppear {
            locationService.requestPermission()
        }
        .sheet(isPresented: $showMapSelector) {
            NavigationView {
                if let pickupCoord = getPickupCoordinate() {
                    MapDestinationPicker(
                        selectedDestination: $selectedDestinationCoord,
                        selectedAddress: $selectedDestinationAddress,
                        pickupLocation: pickupCoord,
                        pickupAddress: viewModel.lugarRecogida.isEmpty ? "Ubicación de recogida" : viewModel.lugarRecogida,
                        onDestinationConfirmed: { coordinate, address in
                            viewModel.destino = address
                            viewModel.destinoCoordinate = coordinate
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
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Primero ingresa la ubicación de recogida")
                            .font(.headline)

                        Button("Cerrar") {
                            showMapSelector = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
    }
    
    private var timeSlots: [String] {
        [
            "00:00-01:00", "01:00-02:00", "02:00-03:00",
            "03:00-04:00", "04:00-05:00", "05:00-06:00",
            "06:00-07:00", "07:00-08:00", "08:00-09:00",
            "09:00-10:00", "10:00-11:00", "11:00-12:00",
            "12:00-13:00", "13:00-14:00", "14:00-15:00",
            "15:00-16:00", "16:00-17:00", "17:00-18:00",
            "18:00-19:00", "19:00-20:00", "20:00-21:00",
            "21:00-22:00", "22:00-23:00", "23:00-00:00"
        ]
    }
    
    private func useCurrentLocation() {
        guard let location = locationService.currentLocation else { return }

        Task {
            do {
                let geocoder = GeocodingService()
                let address = try await geocoder.reverseGeocode(location.coordinate)

                await MainActor.run {
                    viewModel.lugarRecogida = address
                    viewModel.lugarRecogidaCoordinate = location.coordinate
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    private func getPickupCoordinate() -> CLLocationCoordinate2D? {
        // Si ya tenemos las coordenadas guardadas, usarlas
        if let coord = viewModel.lugarRecogidaCoordinate {
            return coord
        }

        // Si tenemos la ubicación actual, usarla
        if let location = locationService.currentLocation {
            return location.coordinate
        }

        // Por defecto, usar Valencia
        return CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763)
    }
}
