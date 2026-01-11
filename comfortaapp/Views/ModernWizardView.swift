import SwiftUI
import CoreLocation

struct ModernWizardView: View {
    @StateObject private var viewModel = WizardViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var progressAnimation = 0.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Header with Progress
                    headerView
                    
                    // Content
                    contentView
                    
                    // Bottom Actions
                    bottomActionsView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(ComfortaDesign.Animation.medium) {
                    progressAnimation = Double(viewModel.currentStep) / 3.0
                }
            }
            .onChange(of: viewModel.currentStep) { _, newStep in
                withAnimation(ComfortaDesign.Animation.medium) {
                    progressAnimation = Double(newStep) / 3.0
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                ComfortaDesign.Colors.background,
                ComfortaDesign.Colors.surfaceSecondary.opacity(0.8),
                ComfortaDesign.Colors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: ComfortaDesign.Spacing.lg) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(ComfortaDesign.Colors.glassBackground)
                                .background(.ultraThinMaterial, in: Circle())
                        )
                }
                
                Spacer()
                
                Text("Nueva Reserva")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Spacer()
                
                if viewModel.currentStep > 1 {
                    Button(action: { 
                        withAnimation(ComfortaDesign.Animation.medium) {
                            viewModel.goToPreviousStep()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.1))
                                    .background(.ultraThinMaterial, in: Circle())
                            )
                    }
                } else {
                    Color.clear
                        .frame(width: 32, height: 32)
                }
            }
            
            // Progress Indicator
            progressIndicator
        }
        .padding(.horizontal, ComfortaDesign.Spacing.lg)
        .padding(.top, ComfortaDesign.Spacing.md)
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: ComfortaDesign.Spacing.sm) {
            // Progress Bar
            HStack(spacing: ComfortaDesign.Spacing.xs) {
                ForEach(1...3, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundColor(
                            step <= viewModel.currentStep ? 
                            ComfortaDesign.Colors.primaryGreen : 
                            ComfortaDesign.Colors.glassBorder
                        )
                        .animation(ComfortaDesign.Animation.medium.delay(Double(step - 1) * 0.1), value: viewModel.currentStep)
                }
            }
            
            // Step Title
            Text(stepTitle)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .animation(.none, value: viewModel.currentStep)
        }
    }
    
    private var stepTitle: String {
        switch viewModel.currentStep {
        case 1: return "Paso 1 de 3 • Datos del viaje"
        case 2: return "Paso 2 de 3 • Información del pasajero"
        case 3: return "Paso 3 de 3 • Confirmación"
        default: return ""
        }
    }
    
    // MARK: - Content
    
    private var contentView: some View {
        TabView(selection: $viewModel.currentStep) {
            // Step 1 - Trip Data
            ModernStep1View(viewModel: viewModel)
                .tag(1)
            
            // Step 2 - Passenger Data
            ModernStep2View(viewModel: viewModel)
                .tag(2)
            
            // Step 3 - Confirmation
            ModernStep3View(viewModel: viewModel)
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(ComfortaDesign.Animation.medium, value: viewModel.currentStep)
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActionsView: some View {
        VStack(spacing: ComfortaDesign.Spacing.md) {
            // Continue Button
            LiquidButton(
                continueButtonText,
                icon: continueButtonIcon,
                style: .primary,
                size: .large
            ) {
                handleContinueAction()
            }
            .disabled(!canContinue)
            .opacity(canContinue ? 1.0 : 0.6)
            .animation(ComfortaDesign.Animation.fast, value: canContinue)
            
            // Step Indicators
            HStack(spacing: ComfortaDesign.Spacing.md) {
                ForEach(1...3, id: \.self) { step in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(
                            step == viewModel.currentStep ? 
                            ComfortaDesign.Colors.primaryGreen : 
                            ComfortaDesign.Colors.glassBorder
                        )
                        .animation(ComfortaDesign.Animation.medium, value: viewModel.currentStep)
                }
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.lg)
        .padding(.bottom, ComfortaDesign.Spacing.xl)
    }
    
    private var continueButtonText: String {
        switch viewModel.currentStep {
        case 1: return "Continuar"
        case 2: return "Revisar reserva"
        case 3: return "Confirmar reserva"
        default: return "Continuar"
        }
    }
    
    private var continueButtonIcon: String {
        switch viewModel.currentStep {
        case 1: return "arrow.right"
        case 2: return "checkmark.circle"
        case 3: return "car.fill"
        default: return "arrow.right"
        }
    }
    
    private var canContinue: Bool {
        switch viewModel.currentStep {
        case 1: return viewModel.isStep1Valid
        case 2: return viewModel.isStep2Valid
        case 3: return true
        default: return false
        }
    }
    
    private func handleContinueAction() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if viewModel.currentStep < 3 {
            withAnimation(ComfortaDesign.Animation.medium) {
                viewModel.goToNextStep()
            }
        } else {
            // Confirm booking
            // TODO: Implement booking confirmation
            dismiss()
        }
    }
}

// MARK: - Step 1 View

struct ModernStep1View: View {
    @ObservedObject var viewModel: WizardViewModel
    @StateObject private var locationService = LocationService()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.xl) {
                // Current Location Card
                currentLocationCard
                
                // Search Fields
                searchFieldsCard
                
                // Date & Time Card
                dateTimeCard
                
                // Map Preview
                if !viewModel.lugarRecogida.isEmpty && !viewModel.destino.isEmpty {
                    mapPreviewCard
                }
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
        .onAppear {
            locationService.requestPermission()
        }
    }
    
    private var currentLocationCard: some View {
        ModernCard(style: .glass) {
            HStack(spacing: ComfortaDesign.Spacing.md) {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Usar mi ubicación actual")
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Text("Como punto de recogida")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                if locationService.authorizationStatus == .authorizedWhenInUse {
                    Button(action: useCurrentLocation) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                } else {
                    Image(systemName: "location.slash")
                        .font(.system(size: 16))
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                }
            }
        }
    }
    
    private var searchFieldsCard: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                // Pickup Field
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    Label("Punto de recogida", systemImage: "location.circle.fill")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    LiquidSearchField(
                        text: $viewModel.lugarRecogida,
                        selectedAddress: $viewModel.lugarRecogida,
                        placeholder: "¿Dónde te recogemos?",
                        icon: "mappin.circle.fill"
                    )
                }
                
                // Destination Field
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    Label("Destino", systemImage: "flag.checkered.2.crossed")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    LiquidSearchField(
                        text: $viewModel.destino,
                        selectedAddress: $viewModel.destino,
                        placeholder: "¿A dónde vamos?",
                        icon: "flag.fill"
                    )
                }
            }
        }
    }
    
    private var dateTimeCard: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                // Date Picker
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    Label("Fecha y hora del viaje", systemImage: "calendar.circle.fill")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    DatePicker(
                        "Seleccionar fecha y hora",
                        selection: $viewModel.fechaInicio,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(ComfortaDesign.Colors.primaryGreen)
                }
                
                // Time Slot Picker
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    Label("Franja horaria preferida", systemImage: "clock.circle.fill")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    Picker("Franja horaria", selection: $viewModel.franjaHoraria) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Text(slot).tag(slot)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ComfortaDesign.Colors.primaryGreen)
                }
            }
        }
    }
    
    private var mapPreviewCard: some View {
        ModernCard(style: .solid) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Label("Vista previa de la ruta", systemImage: "map.fill")
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                
                MapPreviewView(
                    origin: viewModel.lugarRecogida,
                    destination: viewModel.destino
                )
                .frame(height: 200)
                .cornerRadius(ComfortaDesign.Radius.md)
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
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

// MARK: - Step 2 View

struct ModernStep2View: View {
    @ObservedObject var viewModel: WizardViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.xl) {
                // Passenger Info Card
                passengerInfoCard
                
                // Trip Details Card
                tripDetailsCard
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
    }
    
    private var passengerInfoCard: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                Label("Información del pasajero", systemImage: "person.circle.fill")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Name Field
                ModernTextField(
                    text: $viewModel.nombrePasajero,
                    placeholder: "Nombre completo",
                    icon: "person.fill"
                )
                
                // Phone Field
                ModernTextField(
                    text: $viewModel.telefonoPasajero,
                    placeholder: "Número de teléfono",
                    icon: "phone.fill"
                )
            }
        }
    }
    
    private var tripDetailsCard: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                Label("Detalles del viaje", systemImage: "car.circle.fill")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Number of Passengers
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Número de pasajeros")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("\(viewModel.numeroPersonas) persona\(viewModel.numeroPersonas > 1 ? "s" : "")")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Stepper("", value: $viewModel.numeroPersonas, in: 1...8)
                        .labelsHidden()
                }
                
                // Additional Luggage
                Toggle(isOn: $viewModel.equipajeAdicional) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipaje adicional")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("Maletas grandes o equipamiento especial")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
                .tint(ComfortaDesign.Colors.primaryGreen)
                
                // Special Notes
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    Text("Notas especiales (opcional)")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    TextField("Agregar instrucciones adicionales...", text: $viewModel.notasEspeciales, axis: .vertical)
                        .font(ComfortaDesign.Typography.body2)
                        .lineLimit(3...6)
                        .padding(ComfortaDesign.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.sm)
                                .fill(ComfortaDesign.Colors.surfaceSecondary)
                        )
                }
            }
        }
    }
}

// MARK: - Step 3 View

struct ModernStep3View: View {
    @ObservedObject var viewModel: WizardViewModel
    @State private var pricing: PricingResponse?
    @State private var isLoadingPricing = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.xl) {
                // Trip Summary Card
                tripSummaryCard
                
                // Map Card
                if !viewModel.lugarRecogida.isEmpty && !viewModel.destino.isEmpty {
                    mapCard
                }
                
                // Pricing Card
                pricingCard
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
        .task {
            await loadPricing()
        }
    }
    
    private var tripSummaryCard: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.lg) {
                Label("Resumen de la reserva", systemImage: "doc.text.fill")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                VStack(spacing: ComfortaDesign.Spacing.md) {
                    // Route Info
                    tripInfoRow(
                        icon: "location.circle.fill",
                        title: "Recogida",
                        subtitle: viewModel.lugarRecogida,
                        color: ComfortaDesign.Colors.primaryGreen
                    )
                    
                    tripInfoRow(
                        icon: "flag.checkered.2.crossed",
                        title: "Destino",
                        subtitle: viewModel.destino,
                        color: ComfortaDesign.Colors.destinationMarker
                    )
                    
                    // Date & Time
                    tripInfoRow(
                        icon: "calendar.circle.fill",
                        title: "Fecha y hora",
                        subtitle: viewModel.fechaInicio.formatted(date: .abbreviated, time: .shortened),
                        color: ComfortaDesign.Colors.info
                    )
                    
                    // Passengers
                    tripInfoRow(
                        icon: "person.2.fill",
                        title: "Pasajeros",
                        subtitle: "\(viewModel.numeroPersonas) persona\(viewModel.numeroPersonas > 1 ? "s" : "")",
                        color: ComfortaDesign.Colors.textSecondary
                    )
                }
            }
        }
    }
    
    private var mapCard: some View {
        ModernCard(style: .solid) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Label("Ruta del viaje", systemImage: "map.fill")
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                
                InteractiveMapView(
                    origin: viewModel.lugarRecogida,
                    destination: viewModel.destino
                )
                .frame(height: 250)
                .cornerRadius(ComfortaDesign.Radius.md)
            }
        }
    }
    
    private var pricingCard: some View {
        ModernCard(style: .floating) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.lg) {
                if isLoadingPricing {
                    HStack {
                        ProgressView()
                            .tint(ComfortaDesign.Colors.primaryGreen)
                        Text("Calculando precio...")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                } else if let pricing = pricing {
                    Label("Detalles del precio", systemImage: "creditcard.fill")
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    VStack(spacing: ComfortaDesign.Spacing.md) {
                        priceRow("Tarifa base", String(format: "€%.2f", pricing.priceBreakdown.baseRate))
                        priceRow("Por distancia", String(format: "€%.2f", pricing.priceBreakdown.distanceRate))
                        priceRow("Por tiempo", String(format: "€%.2f", pricing.priceBreakdown.timeRate))
                        
                        Divider()
                            .background(ComfortaDesign.Colors.glassBorder)
                        
                        HStack {
                            Text("Total")
                                .font(ComfortaDesign.Typography.title3)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text(String(format: "€%.2f", pricing.totalPrice))
                                .font(ComfortaDesign.Typography.title2)
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        }
                    }
                }
            }
        }
    }
    
    private func tripInfoRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: ComfortaDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                
                Text(subtitle)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }
            
            Spacer()
        }
    }
    
    private func priceRow(_ title: String, _ amount: String) -> some View {
        HStack {
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
            
            Spacer()
            
            Text(amount)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
    }
    
    private func loadPricing() async {
        isLoadingPricing = true
        defer { isLoadingPricing = false }
        
        do {
            pricing = try await PricingService.shared.calculatePricing(
                origin: viewModel.lugarRecogida,
                destination: viewModel.destino
            )
        } catch {
            print("Error loading pricing: \(error)")
        }
    }
}

// MARK: - Modern Text Field

struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
        .padding(ComfortaDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.sm)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}
