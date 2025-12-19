import SwiftUI
import Combine

struct WizardView: View {
    @StateObject private var viewModel = WizardViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(viewModel.currentStep), total: 3)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    Step1TripDataView(viewModel: viewModel)
                        .tag(1)
                    
                    Step2PassengerDataView(viewModel: viewModel)
                        .tag(2)
                    
                    Step3ConfirmationView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }
            .navigationTitle("Nueva reserva")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                if viewModel.currentStep > 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Atrás") {
                            viewModel.goToPreviousStep()
                        }
                    }
                }
            }
        }
    }
}

struct Step2PassengerDataView: View {
    @ObservedObject var viewModel: WizardViewModel
    
    var body: some View {
        Form {
            Section("Datos del pasajero") {
                TextField("Nombre completo", text: $viewModel.nombrePasajero)
                    .textContentType(.name)
                
                TextField("Teléfono", text: $viewModel.telefonoPasajero)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            
            Section("Detalles del viaje") {
                Stepper("Número de pasajeros: \(viewModel.numeroPersonas)", 
                       value: $viewModel.numeroPersonas, 
                       in: 1...8)
                
                Toggle("Equipaje adicional", isOn: $viewModel.equipajeAdicional)
                
                TextField("Notas especiales (opcional)", text: $viewModel.notasEspeciales, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Button("Continuar") {
                viewModel.goToNextStep()
            }
            .disabled(!viewModel.isStep2Valid)
        }
        .navigationTitle("Datos del pasajero")
    }
}

struct Step3ConfirmationView: View {
    @ObservedObject var viewModel: WizardViewModel
    @State private var pricing: PricingResponse?
    @State private var isLoadingPricing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map preview
                if !viewModel.lugarRecogida.isEmpty && !viewModel.destino.isEmpty {
                    InteractiveMapView(
                        origin: viewModel.lugarRecogida,
                        destination: viewModel.destino
                    )
                    .frame(height: 250)
                    .cornerRadius(12)
                }
                
                // Trip summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Recogida")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.lugarRecogida)
                                .font(.body)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Destino")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.destino)
                                .font(.body)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Fecha y hora")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.fechaInicio.formatted(date: .abbreviated, time: .shortened))
                                .font(.body)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Pasajeros")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.numeroPersonas) persona\(viewModel.numeroPersonas > 1 ? "s" : "")")
                                .font(.body)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Pricing
                if let pricing = pricing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detalles del precio")
                            .font(.headline)
                        
                        HStack {
                            Text("Distancia:")
                            Spacer()
                            Text("\(pricing.distance, specifier: "%.1f") km")
                        }
                        
                        HStack {
                            Text("Tiempo estimado:")
                            Spacer()
                            Text(pricing.estimatedTime)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Tarifa base:")
                            Spacer()
                            Text("€\(pricing.priceBreakdown.baseRate, specifier: "%.2f")")
                        }
                        
                        HStack {
                            Text("Por distancia:")
                            Spacer()
                            Text("€\(pricing.priceBreakdown.distanceRate, specifier: "%.2f")")
                        }
                        
                        HStack {
                            Text("Por tiempo:")
                            Spacer()
                            Text("€\(pricing.priceBreakdown.timeRate, specifier: "%.2f")")
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total:")
                                .font(.headline)
                            Spacer()
                            Text("€\(pricing.totalPrice, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else if isLoadingPricing {
                    HStack {
                        ProgressView()
                        Text("Calculando precio...")
                    }
                    .padding()
                }
                
                Button("Confirmar reserva") {
                    // TODO: Implement booking
                }
                .buttonStyle(.borderedProminent)
                .disabled(pricing == nil || viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("Confirmación")
        .task {
            await loadPricing()
        }
    }
    
    private func loadPricing() async {
        isLoadingPricing = true
        defer { isLoadingPricing = false }
        
        do {
            let pricingService = PricingService()
            pricing = try await pricingService.calculatePricing(
                origin: viewModel.lugarRecogida,
                destination: viewModel.destino
            )
        } catch {
            print("Error loading pricing: \(error)")
        }
    }
}