import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct ModernRideView: View {
    @StateObject private var viewModel = SimpleRideViewModel()
    @StateObject private var connectivity = ConnectivityMonitor()
    @State private var showingWizard = false
    @State private var animateBackground = false
    @State private var hasTrackedHome = false
    @State private var showPaywall = false
    @State private var isFormExpanded = false
    @State private var selectedPlannerMode: PlannerMode = .now
    @State private var scheduledDate = Date()

    private let quickDestinations: [QuickDestination] = [
        QuickDestination(
            title: "Casa",
            subtitle: "Av. del Puerto 22",
            coordinate: CLLocationCoordinate2D(latitude: 39.4667, longitude: -0.3566)
        ),
        QuickDestination(
            title: "Trabajo",
            subtitle: "Gran Vía Marqués del Turia 15",
            coordinate: CLLocationCoordinate2D(latitude: 39.4707, longitude: -0.3768)
        ),
        QuickDestination(
            title: "Aeropuerto",
            subtitle: "Aeropuerto VLC",
            coordinate: CLLocationCoordinate2D(latitude: 39.4916, longitude: -0.4733)
        )
    ]

    let userName: String
    let onLogout: () -> Void
    
    init(
        userName: String, 
        onLogout: @escaping () -> Void
    ) {
        self.userName = userName
        self.onLogout = onLogout
    }
    
    
    var body: some View {
        ZStack {
            // Background with animated gradient
            backgroundView
            
            // Map Layer
            mapView
            
            // Content Overlay
            VStack(spacing: ComfortaDesign.Spacing.md) {
                topHeader
                quickDestinationsRow
                Spacer()
                bottomContent
            }
            .padding(.top, ComfortaDesign.Spacing.sm)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: viewModel.currentTripState) { _, newValue in
            if newValue == .completed || newValue == .cancelled {
                isFormExpanded = false
            }
        }
    }
        .onAppear {
            if !hasTrackedHome {
                AnalyticsService.shared.track(.viewHome)
                hasTrackedHome = true
            }
            withAnimation(ComfortaDesign.Animation.slow) {
                animateBackground = true
            }
        }
        .sheet(isPresented: $showingWizard) {
            ModernWizardView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                fare: viewModel.estimatedFare,
                distance: viewModel.estimatedDistance,
                onConfirm: {
                    showPaywall = false
                    AnalyticsService.shared.track(.payConfirmed)
                },
                onCancel: {
                    showPaywall = false
                    AnalyticsService.shared.track(.payCancelled)
                }
            )
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ComfortaDesign.Colors.background,
                    .black,
                    ComfortaDesign.Colors.background
                ],
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .animation(ComfortaDesign.Animation.slow.repeatForever(autoreverses: true), value: animateBackground)
            
            Circle()
                .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.18))
                .blur(radius: 120)
                .frame(width: 320, height: 320)
                .offset(x: animateBackground ? -140 : -80, y: -160)
                .animation(ComfortaDesign.Animation.slow.repeatForever(autoreverses: true), value: animateBackground)
            
            Circle()
                .fill(ComfortaDesign.Colors.lightGreen.opacity(0.22))
                .blur(radius: 140)
                .frame(width: 300, height: 300)
                .offset(x: animateBackground ? 120 : 80, y: 240)
                .animation(ComfortaDesign.Animation.slow.repeatForever(autoreverses: true), value: animateBackground)
            
            LinearGradient(
                colors: [
                    .clear,
                    ComfortaDesign.Colors.primaryGreen.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        InteractiveRideMap(
            region: $viewModel.mapRegion,
            annotations: mapAnnotations,
            route: viewModel.routePolyline,
            isLoadingRoute: viewModel.isCalculatingRoute,
            onTap: hideKeyboard,
            onCenterUser: viewModel.useCurrentLocation,
            onResetRoute: viewModel.clearTrip
        )
    }
    
    // MARK: - Top Header
    
    private var topHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: ComfortaDesign.Colors.glassShadow, radius: 10, x: 0, y: 6)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Comforta")
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("Viaje a larga distancia al precio verdadero")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
                
                Text("Hola, \(userName.isEmpty ? "Viajero" : userName)")
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    .padding(.horizontal, ComfortaDesign.Spacing.sm)
                    .padding(.vertical, ComfortaDesign.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(ComfortaDesign.Colors.surfaceSecondary)
                            .overlay(
                                Capsule()
                                    .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                            )
                    )
                if connectivity.isOffline {
                    Text("Sin conexión. El mapa puede no actualizar.")
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.warning)
                        .padding(.horizontal, ComfortaDesign.Spacing.sm)
                        .padding(.vertical, ComfortaDesign.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(ComfortaDesign.Colors.surfaceSecondary)
                                .overlay(
                                    Capsule()
                                        .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                                )
                        )
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: ComfortaDesign.Spacing.sm) {
                // Settings Button
                Button(action: {}) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(ComfortaDesign.Colors.glassBackground)
                                .background(.ultraThinMaterial, in: Circle())
                        )
                        .overlay(
                            Circle()
                                .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                        )
                }
                
                // Profile Button
                Button(action: onLogout) {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(ComfortaDesign.Colors.glassBackground)
                                .background(.ultraThinMaterial, in: Circle())
                        )
                        .overlay(
                            Circle()
                                .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.lg)
        .padding(.top, ComfortaDesign.Spacing.md)
    }
    
    private var quickDestinationsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ComfortaDesign.Spacing.sm) {
                ForEach(quickDestinations) { destination in
                    QuickDestinationChip(destination: destination) {
                        selectQuickDestination(destination)
                    }
                }
                Button {
                    showingWizard = true
                } label: {
                    Label("Wizard", systemImage: "sparkles")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        .padding(.horizontal, ComfortaDesign.Spacing.md)
                        .padding(.vertical, ComfortaDesign.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                                .fill(ComfortaDesign.Colors.surfaceSecondary)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
    }
    
    // MARK: - Bottom Content
    
    private var bottomContent: some View {
        VStack(spacing: ComfortaDesign.Spacing.md) {
            if shouldShowActiveTrip {
                activeTripContent
            } else if isFormExpanded {
                regularBottomContent
            } else {
                collapsedPrompt
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.lg)
        .padding(.bottom, ComfortaDesign.Spacing.xl)
    }

    private var shouldShowActiveTrip: Bool {
        (viewModel.currentTrip != nil && viewModel.currentTripState != .searchingLocations) || viewModel.assignedDriver != nil
    }

    @ViewBuilder
    private var activeTripContent: some View {
        switch viewModel.currentTripState {
        case .readyToConfirm:
            if let trip = viewModel.currentTrip {
                TripConfirmationView(
                    trip: trip,
                    onConfirm: {
                        viewModel.confirmTrip()
                    },
                    onCancel: {
                        viewModel.clearTrip()
                        isFormExpanded = false
                    }
                )
            } else {
                collapsedPrompt
            }
        case .driverAssigned:
            if let driver = viewModel.assignedDriver, let trip = viewModel.currentTrip {
                DriverAssignedView(
                    driver: driver,
                    trip: trip,
                    onContinue: {
                        viewModel.currentTripState = .driverEnRoute
                    }
                )
            } else {
                collapsedPrompt
            }
        case .driverEnRoute, .driverArrived, .inProgress, .findingDriver, .processingPayment, .confirmingTrip:
            ActiveStatusCard(state: viewModel.currentTripState, trip: viewModel.currentTrip)
        default:
            collapsedPrompt
        }
    }

    private var regularBottomContent: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                singleForm
                rideModeSelector
                if selectedPlannerMode == .schedule {
                    DatePicker(
                        "Programar",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(ComfortaDesign.Colors.primaryGreen)
                }
                if isRideReady {
                    Divider().background(ComfortaDesign.Colors.glassBorder)
                    summaryInline
                }
                LiquidButton(
                    buttonText,
                    icon: buttonIcon,
                    style: .primary,
                    size: .medium
                ) {
                    buttonAction()
                }
            }
        }
    }

    private var collapsedPrompt: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                HStack(spacing: ComfortaDesign.Spacing.sm) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text("Planea tu próximo viaje")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }
                Text("Toca para elegir origen y destino")
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                LiquidButton(
                    "Buscar viaje",
                    icon: "magnifyingglass",
                    style: .primary,
                    size: .medium
                ) {
                    withAnimation(ComfortaDesign.Animation.spring) {
                        isFormExpanded = true
                        viewModel.currentTripState = .searchingLocations
                    }
                }
            }
        }
    }
    
    private var isRideReady: Bool {
        viewModel.pickupCoordinate != nil && viewModel.destinationCoordinate != nil
    }
    
    private var buttonText: String {
        switch viewModel.currentTripState {
        case .readyToConfirm:
            return "Confirmar"
        case .searchingLocations:
            return isRideReady ? "Actualizar ruta" : "Elegir destino"
        default:
            return "Elegir destino"
        }
    }
    
    private var buttonIcon: String {
        switch viewModel.currentTripState {
        case .readyToConfirm:
            return "checkmark.circle.fill"
        default:
            return "arrow.triangle.turn.up.right.diamond.fill"
        }
    }
    
    private func buttonAction() {
        switch viewModel.currentTripState {
        case .readyToConfirm:
            if viewModel.currentTrip != nil {
                viewModel.confirmTrip()
            } else {
                viewModel.calculateFare()
            }
        default:
            viewModel.calculateFare()
        }
        var metadata: [String: String] = ["mode": selectedPlannerMode.rawValue]
        if selectedPlannerMode == .schedule {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            metadata["scheduled_at"] = formatter.string(from: scheduledDate)
        }
        AnalyticsService.shared.track(.requestRide, metadata: metadata)
        isFormExpanded = true
    }
    
    private var singleForm: some View {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                LiquidSearchField(
                    text: $viewModel.pickupText,
                    selectedAddress: Binding(
                        get: { viewModel.pickupText },
                        set: { _ in }
                    ),
                    placeholder: "Tu recogida (auto)",
                    icon: "location.circle.fill",
                    onCurrentLocation: {
                        viewModel.useCurrentLocation()
                    },
                    onSelection: { address, coordinate in
                        viewModel.setPickup(address: address, coordinate: coordinate)
                    }
                )
                .accessibilityLabel("Campo de recogida")
                .onTapGesture {
                    AnalyticsService.shared.track(.searchPickup)
                }
                
                Button {
                    viewModel.swapLocations()
                    AnalyticsService.shared.track(.swapLocations)
                } label: {
                    HStack(spacing: ComfortaDesign.Spacing.xs) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                        Text("Intercambiar origen/destino")
                    }
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
                .padding(.vertical, ComfortaDesign.Spacing.xs)
                
                LiquidSearchField(
                    text: $viewModel.destinationText,
                    selectedAddress: Binding(
                        get: { viewModel.destinationText },
                        set: { _ in }
                    ),
                    placeholder: "Destino",
                    icon: "flag.checkered.2.crossed",
                    onSelection: { address, coordinate in
                        viewModel.setDestination(address: address, coordinate: coordinate)
                    }
                )
                .accessibilityLabel("Campo de destino")
                .onTapGesture {
                    AnalyticsService.shared.track(.searchDestination)
                }
            }
        }
    
    private var summaryInline: some View    {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.estimatedDistance.isEmpty ? "Distancia" : viewModel.estimatedDistance)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    Text("Kilómetros estimados")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(viewModel.estimatedFare)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text("Precio orientativo")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
            if !viewModel.estimatedDuration.isEmpty {
                Text("ETA: \(viewModel.estimatedDuration)")
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
            if viewModel.isCalculatingRoute {
                ProgressView("Calculando ruta...")
                    .progressViewStyle(CircularProgressViewStyle(tint: ComfortaDesign.Colors.primaryGreen))
                    .font(ComfortaDesign.Typography.caption1)
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.error)
            }
            if connectivity.isOffline {
                Text("Sin conexión: cálculos locales, revisa al volver online")
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.warning)
            }
        }
    }
    
    private var rideModeSelector: some View {
        Picker("", selection: $selectedPlannerMode) {
            ForEach(PlannerMode.allCases, id: \.self) { mode in
                Text(mode.title)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Search Fields
    
    // MARK: - Action Button
    
    private var actionButtonView: some View {
        Group {
            if isRideReady {
                LiquidButton(
                    "Pagar y mandar al cobro",
                    icon: "creditcard.fill",
                    style: .primary,
                    size: .large
                ) {
                    AnalyticsService.shared.track(.confirmRide, metadata: ["action": "pay"])
                    viewModel.calculateFare()
                    showPaywall = true
                }
                .disabled(viewModel.isCalculatingRoute || connectivity.isOffline)
            } else {
                LiquidButton(
                    "Planificar viaje premium",
                    icon: "sparkles",
                    style: .glass,
                    size: .medium
                ) {
                    showingWizard = true
                }
            }
        }
    }
    
    // MARK: - Helper Views and Functions
    
    private var mapAnnotations: [ModernMapAnnotationItem] {
        var annotations: [ModernMapAnnotationItem] = []
        
        if let pickup = viewModel.pickupCoordinate {
            annotations.append(ModernMapAnnotationItem(
                coordinate: pickup,
                type: .pickup,
                title: "Recogida"
            ))
        }
        
        if let destination = viewModel.destinationCoordinate {
            annotations.append(ModernMapAnnotationItem(
                coordinate: destination,
                type: .destination,
                title: "Destino"
            ))
        }

        return annotations
    }
    
    private func selectQuickDestination(_ destination: QuickDestination) {
        viewModel.setDestination(address: destination.subtitle, coordinate: destination.coordinate)
        if viewModel.pickupCoordinate == nil {
            viewModel.useCurrentLocation()
        }
        withAnimation(ComfortaDesign.Animation.spring) {
            isFormExpanded = true
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct ActiveStatusCard: View {
    let state: TripState
    let trip: Trip?
    
    var body: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                HStack(spacing: ComfortaDesign.Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(ComfortaDesign.Colors.primaryGreen)
                    Text(state.displayName)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }
                
                if let trip = trip {
                    VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
                        Text(trip.pickupLocation.address)
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Text(trip.destinationLocation.address)
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: ComfortaDesign.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ComfortaDesign.Colors.glassBackground.opacity(0.9),
                                        ComfortaDesign.Colors.glassHighlight.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                            )
                            .shadow(
                                color: ComfortaDesign.Colors.glassShadow,
                                radius: isPressed ? 4 : 8,
                                x: 0,
                                y: isPressed ? 2 : 4
                            )
                    )
                
                Text(title)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 60)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(ComfortaDesign.Animation.fast, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(ComfortaDesign.Animation.fast) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Map Enhancements

struct InteractiveRideMap: View {
    @Binding var region: MKCoordinateRegion
    let annotations: [ModernMapAnnotationItem]
    let route: MKPolyline?
    let isLoadingRoute: Bool
    let onTap: () -> Void
    let onCenterUser: () -> Void
    let onResetRoute: () -> Void
    
    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: annotations
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    ModernMapPin(type: annotation.type, title: annotation.title)
                }
            }
            .ignoresSafeArea()
            
            if let polyline = route {
                RouteOverlayView(polyline: polyline, region: region)
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: ComfortaDesign.Spacing.sm) {
                MapActionButton(icon: "location.fill", title: "Ubicar", action: onCenterUser)
                MapActionButton(icon: "arrow.uturn.left", title: "Limpiar", action: onResetRoute)
            }
            .padding(ComfortaDesign.Spacing.lg)
        }
        .overlay(alignment: .topLeading) {
            MapStatusBadge(isLoading: isLoadingRoute, hasRoute: route != nil)
                .padding(ComfortaDesign.Spacing.lg)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct MapActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ComfortaDesign.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ComfortaDesign.Spacing.sm)
            .padding(.vertical, ComfortaDesign.Spacing.xs)
            .background(
                Capsule()
                    .fill(ComfortaDesign.Colors.glassBackground)
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MapStatusBadge: View {
    let isLoading: Bool
    let hasRoute: Bool
    
    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: isLoading ? "hourglass" : "bolt.car")
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text(isLoading ? "Calculando ruta" : (hasRoute ? "Ruta lista" : "Explora la zona"))
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(.white)
                Text(hasRoute ? "Optimizada para menor coste" : "Toca un destino sugerido")
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.md)
        .padding(.vertical, ComfortaDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                .fill(ComfortaDesign.Colors.surfaceSecondary.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Modern Map Pin

struct ModernMapPin: View {
    let type: MapPinType
    let title: String
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(pinColor.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .scaleEffect(animate ? 1.2 : 1.0)
                    .opacity(animate ? 0 : 1)
                
                // Main pin
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                pinColor,
                                pinColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: pinColor.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Image(systemName: pinIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Label
            Text(title)
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(ComfortaDesign.Colors.surface)
                        .shadow(
                            color: ComfortaDesign.Colors.glassShadow,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
        }
        .onAppear {
            withAnimation(ComfortaDesign.Animation.spring.repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
    
    private var pinColor: Color {
        switch type {
        case .pickup:
            return ComfortaDesign.Colors.pickupMarker
        case .destination:
            return ComfortaDesign.Colors.destinationMarker
        }
    }
    
    private var pinIcon: String {
        switch type {
        case .pickup:
            return "location.fill"
        case .destination:
            return "flag.fill"
        }
    }
}

// MARK: - Route Overlay

struct RouteOverlayView: View {
    let polyline: MKPolyline
    let region: MKCoordinateRegion

    var body: some View {
        GeometryReader { geo in
            let points = polyline.coordinates.map { coordinate in
                point(for: coordinate, in: geo.size)
            }
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                LinearGradient(
                    colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.lightGreen],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: ComfortaDesign.Colors.glassShadow, radius: 4, x: 0, y: 2)
        }
        .allowsHitTesting(false)
    }
    
    private func point(for coordinate: CLLocationCoordinate2D, in size: CGSize) -> CGPoint {
        let span = region.span
        guard span.latitudeDelta != 0, span.longitudeDelta != 0 else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        let xRatio = (coordinate.longitude - region.center.longitude) / span.longitudeDelta
        let yRatio = (region.center.latitude - coordinate.latitude) / span.latitudeDelta
        let x = size.width / 2 + CGFloat(xRatio) * size.width
        let y = size.height / 2 + CGFloat(yRatio) * size.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Supporting Types

struct ModernMapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MapPinType
    let title: String
}

enum MapPinType {
    case pickup
    case destination
}

// MARK: - Quick Destinations

struct QuickDestination: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}

struct QuickDestinationChip: View {
    let destination: QuickDestination
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.title)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                Text(destination.subtitle)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .padding(.vertical, ComfortaDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                            .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum PlannerMode: String, CaseIterable {
    case now
    case schedule
    
    var title: String {
        switch self {
        case .now:
            return "Ahora"
        case .schedule:
            return "Programar"
        }
    }
}

// MARK: - MKPolyline helper

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
