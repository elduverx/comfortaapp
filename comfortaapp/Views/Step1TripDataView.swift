import SwiftUI
import Combine
import CoreLocation

struct Step1TripDataView: View {
    @ObservedObject var viewModel: WizardViewModel
    @StateObject private var locationService = LocationService()
    
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
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}