import SwiftUI
import MapKit
import CoreLocation

// MARK: - Professional Ride View

struct ProfessionalRideView: View {
    @StateObject private var viewModel = SimpleRideViewModel()
    @StateObject private var connectivity = ConnectivityMonitor()

    @State private var bottomSheetPosition: BottomSheetPosition = .peek
    @State private var showingTripConfirmation = false
    @State private var hasTrackedHome = false
    @State private var mapZoomLevel: Double = 0.05
    @State private var isMapSelectionMode = false
    @State private var tempSelectedLocation: CLLocationCoordinate2D?
    @State private var tempSelectedAddress: String?
    @State private var isLoadingAddress = false

    let userName: String
    let onLogout: () -> Void
    let onProfileTap: () -> Void

    init(
        userName: String,
        onLogout: @escaping () -> Void,
        onProfileTap: @escaping () -> Void
    ) {
        self.userName = userName
        self.onLogout = onLogout
        self.onProfileTap = onProfileTap
    }

    var body: some View {
        ZStack {
            // Full Screen Map with MapReader for tap detection
            if isMapSelectionMode {
                mapViewWithTapDetection
                    .ignoresSafeArea()
            } else {
                mapView
                    .ignoresSafeArea()
            }

            // Map Selection Mode Overlay
            if isMapSelectionMode {
                mapSelectionOverlay
            }

            // Floating Controls Overlay
            if !isMapSelectionMode {
                floatingControls
            }

            // Bottom Sheet with Search and Details
            if !isMapSelectionMode {
                BottomSheet(position: $bottomSheetPosition, backgroundColor: ComfortaDesign.Colors.surface) {
                    bottomSheetContent
                }
            }

            // Confirmation panel when address is loaded
            if isMapSelectionMode, let address = tempSelectedAddress, !isLoadingAddress {
                confirmationPanel(address: address)
            }

            // Loading indicator
            if isLoadingAddress {
                loadingIndicator
            }
        }
        .onAppear {
            if !hasTrackedHome {
                AnalyticsService.shared.track(.viewHome)
                hasTrackedHome = true
            }
            viewModel.useCurrentLocation()
            viewModel.refreshTripStatusIfNeeded()
            viewModel.resumeTripMonitoringIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showActiveTrip)) { notification in
            guard let tripId = notification.userInfo?["trip_id"] as? String else { return }
            handleTripNotification(tripId: tripId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTripDetails)) { notification in
            guard let tripId = notification.userInfo?["trip_id"] as? String else { return }
            handleTripNotification(tripId: tripId)
        }
        .onChange(of: viewModel.currentTripState) { _, newValue in
            switch newValue {
            case .confirmingTrip, .processingPayment, .findingDriver, .driverAssigned, .driverEnRoute, .driverArrived, .inProgress:
                if bottomSheetPosition == .peek {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        bottomSheetPosition = .middle
                    }
                }
            default:
                break
            }
        }
        .sheet(isPresented: $showingTripConfirmation) {
            if let trip = viewModel.currentTrip {
                TripConfirmationView(
                    trip: trip,
                    onConfirm: {
                        viewModel.confirmTrip()
                        showingTripConfirmation = false
                    },
                    onCancel: {
                        showingTripConfirmation = false
                    }
                )
            }
        }
    }

    private func handleTripNotification(tripId: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            bottomSheetPosition = .middle
        }
        isMapSelectionMode = false
        viewModel.handleTripNotification(tripId: tripId)
    }

    // MARK: - Map View

    private var mapView: some View {
        RouteMapView(
            region: $viewModel.mapRegion,
            annotations: mapAnnotations.map {
                RouteMapAnnotation(
                    coordinate: $0.coordinate,
                    title: $0.title,
                    tint: markerTint(for: $0.type)
                )
            },
            route: viewModel.routePolyline,
            showsUserLocation: shouldShowUserLocation
        )
        .onTapGesture {
            hideKeyboard()
        }
    }

    private var mapViewWithTapDetection: some View {
        MapReader { proxy in
            Map(position: .constant(.region(viewModel.mapRegion))) {
                // Pin de recogida
                if let pickup = viewModel.pickupCoordinate {
                    Annotation("Recogida", coordinate: pickup) {
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 40, height: 40)
                                .shadow(radius: 4)

                            Image(systemName: "figure.walk.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 20))
                        }
                    }
                }

                // Pin temporal durante selección
                if let tempLoc = tempSelectedLocation {
                    Annotation("Seleccionado", coordinate: tempLoc) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 44, height: 44)
                                .shadow(color: .blue.opacity(0.5), radius: 8)

                            Circle()
                                .fill(.white)
                                .frame(width: 36, height: 36)

                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.system(size: 20))
                        }
                        .scaleEffect(isLoadingAddress ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatForever(), value: isLoadingAddress)
                    }
                }

                // Ruta si existe
                if let route = viewModel.routePolyline {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
            .onTapGesture { screenPosition in
                if let coordinate = proxy.convert(screenPosition, from: .local) {
                    handleMapTapAtCoordinate(coordinate)
                }
            }
        }
    }

    private func markerTint(for type: MapPinType) -> Color {
        switch type {
        case .pickup, .destination:
            return ComfortaDesign.Colors.primaryGreen
        }
    }

    private var shouldShowUserLocation: Bool {
        mapAnnotations.isEmpty
    }

    // MARK: - Floating Controls

    private var floatingControls: some View {
        VStack {
            // Top Bar
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Spacer()

            // Right Side Controls
            HStack {
                Spacer()

                VStack(spacing: 12) {
                    FloatingMapButton(icon: "location.fill") {
                        viewModel.useCurrentLocation()
                        centerMapOnUser()
                    }

                    FloatingMapButton(icon: "plus") {
                        zoomIn()
                    }

                    FloatingMapButton(icon: "minus") {
                        zoomOut()
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, bottomSheetPosition == .peek ? 200 : 400)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            // Menu/Profile Button
            ProfileButton(userName: userName) {
                onProfileTap()
            }

            // Compact Search (when bottom sheet is collapsed)
            if bottomSheetPosition == .peek {
                CompactSearchBar(
                    pickupText: viewModel.pickupText,
                    destinationText: viewModel.destinationText,
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            bottomSheetPosition = .middle
                        }
                    }
                )
            }
        }
    }

    // MARK: - Bottom Sheet Content

    @ViewBuilder
    private var bottomSheetContent: some View {
        switch viewModel.currentTripState {
        case .searchingLocations:
            searchContent
        case .readyToConfirm:
            tripSummaryContent
        case .confirmingTrip, .processingPayment, .findingDriver:
            pendingTripContent
        case .driverAssigned, .driverEnRoute, .driverArrived, .inProgress, .completed:
            activeTripContent
        default:
            searchContent
        }
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            // Header
            Text("¿A dónde vas?")
                .font(ComfortaDesign.Typography.title2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Search Fields
            VStack(spacing: 12) {
                LiquidSearchField(
                    text: $viewModel.pickupText,
                    selectedAddress: Binding(
                        get: { viewModel.pickupText },
                        set: { _ in }
                    ),
                    placeholder: "Ubicación actual",
                    icon: "location.fill",
                    onCurrentLocation: {
                        viewModel.useCurrentLocation()
                    },
                    onSelection: { address, coordinate in
                        viewModel.setPickup(address: address, coordinate: coordinate)
                    }
                )

                LiquidSearchField(
                    text: $viewModel.destinationText,
                    selectedAddress: Binding(
                        get: { viewModel.destinationText },
                        set: { _ in }
                    ),
                    placeholder: "¿A dónde vas?",
                    icon: "mappin.circle.fill",
                    onMapSelection: {
                        enterMapSelectionMode()
                    },
                    onSelection: { address, coordinate in
                        viewModel.setDestination(address: address, coordinate: coordinate)
                        bottomSheetPosition = .middle
                    },
                    onFocusChange: { focused in
                        if focused {
                            bottomSheetPosition = .full
                        }
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
            )
            .padding(.horizontal, 20)

            scheduleSelector
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Quick Actions
            if !quickDestinations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickDestinations) { destination in
                            QuickDestinationCard(destination: destination) {
                                selectQuickDestination(destination)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }

            // Recent Trips
            if bottomSheetPosition == .full {
                recentTripsSection
                    .padding(.top, 24)
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    private var tripSummaryContent: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Resumen del viaje")
                    .font(ComfortaDesign.Typography.title2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Spacer()

                Button(action: {
                    viewModel.clearTrip()
                    bottomSheetPosition = .peek
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Route Info
            VStack(spacing: 16) {
                routeInfoRow(
                    from: viewModel.pickupText,
                    to: viewModel.destinationText
                )

                Divider()
                    .background(ComfortaDesign.Colors.glassBorder)

                serviceTimeRow

                // Trip Stats
                HStack(spacing: 20) {
                    tripStatItem(
                        icon: "timer",
                        label: "Tiempo",
                        value: viewModel.estimatedDuration
                    )

                    Divider()
                        .frame(height: 40)

                    tripStatItem(
                        icon: "location",
                        label: "Distancia",
                        value: viewModel.estimatedDistance
                    )

                    Divider()
                        .frame(height: 40)

                    tripStatItem(
                        icon: "eurosign.circle",
                        label: "Precio",
                        value: viewModel.summaryFareText
                    )
                }
                .padding(.vertical, 12)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
            )
            .padding(.horizontal, 20)

            // Confirm Button
            LiquidButton(
                "Confirmar viaje",
                icon: "checkmark.circle.fill",
                style: .primary,
                size: .large
            ) {
                // Create a preview trip for confirmation
                viewModel.createPreviewTrip()
                showingTripConfirmation = true
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var scheduleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                Text("Hora del servicio")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }

            DatePicker(
                "Fecha y hora del servicio",
                selection: $viewModel.requestedServiceDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .tint(ComfortaDesign.Colors.primaryGreen)

            Text("Tu conductor estará allí a la hora solicitada.")
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }

    private var pendingTripContent: some View {
        let copy = pendingCopy(for: viewModel.currentTripState)

        return VStack(spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: pendingIconName(for: viewModel.currentTripState))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(copy.title)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    Text(copy.subtitle)
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }

                Spacer()

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(ComfortaDesign.Colors.primaryGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
            )
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
                routeInfoRow(
                    from: viewModel.pickupText.isEmpty ? "Recogida" : viewModel.pickupText,
                    to: viewModel.destinationText.isEmpty ? "Destino" : viewModel.destinationText
                )
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ComfortaDesign.Colors.surfaceSecondary)
                )

                tripDetailsCard

                VStack(spacing: 12) {
                    ForEach(pendingSteps(for: viewModel.currentTripState)) { step in
                        pendingStepRow(step)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ComfortaDesign.Colors.surfaceSecondary)
                )
            }
            .padding(.horizontal, 20)

            Text("Tu conductor estará allí a la hora solicitada.")
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var activeTripContent: some View {
        VStack(spacing: 20) {
            Text("Estado del viaje")
                .font(ComfortaDesign.Typography.title2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            if let driver = viewModel.assignedDriver {
                DriverCard(driver: driver)
                    .padding(.horizontal, 20)
            }

            TripStatusIndicator(state: viewModel.currentTripState)
                .padding(.horizontal, 20)

            tripDetailsCard
                .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.recentDestinations.isEmpty {
                Text("Recientes")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .padding(.horizontal, 20)

                ForEach(viewModel.recentDestinations) { destination in
                    RecentTripRow(
                        title: destination.title,
                        subtitle: destination.subtitle,
                        icon: getIconForDestination(destination.title)
                    ) {
                        selectRecentDestination(destination)
                    }
                }
            }
        }
    }

    private func getIconForDestination(_ title: String) -> String {
        let lowercased = title.lowercased()
        if lowercased.contains("casa") || lowercased.contains("home") {
            return "house.fill"
        } else if lowercased.contains("trabajo") || lowercased.contains("office") || lowercased.contains("oficina") {
            return "building.2.fill"
        } else if lowercased.contains("aeropuerto") || lowercased.contains("airport") {
            return "airplane"
        } else if lowercased.contains("hotel") {
            return "bed.double.fill"
        } else if lowercased.contains("restaurante") || lowercased.contains("restaurant") {
            return "fork.knife"
        } else {
            return "mappin.circle.fill"
        }
    }

    private func selectRecentDestination(_ destination: QuickDestination) {
        viewModel.setDestination(address: destination.subtitle, coordinate: destination.coordinate)
        if viewModel.pickupCoordinate == nil {
            viewModel.useCurrentLocation()
        }
        viewModel.calculateFare()
        bottomSheetPosition = .middle
    }

    // MARK: - Helper Views

    private func routeInfoRow(from: String, to: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 8) {
                Circle()
                    .fill(ComfortaDesign.Colors.primaryGreen)
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(ComfortaDesign.Colors.glassBorder)
                    .frame(width: 2)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ComfortaDesign.Colors.error)
            }
            .frame(height: 60)

            VStack(alignment: .leading, spacing: 12) {
                Text(from)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text(to)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }

    private var serviceTimeRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            VStack(alignment: .leading, spacing: 4) {
                Text("Hora del servicio")
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                Text(formattedServiceTime(for: viewModel.currentTrip?.scheduledAt ?? viewModel.requestedServiceDate))
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }

            Spacer()
        }
    }

    private func tripStatItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            Text(value)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .fontWeight(.semibold)

            Text(label)
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Map Helpers

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

    private var quickDestinations: [QuickDestination] {
        [
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
    }

    private func selectQuickDestination(_ destination: QuickDestination) {
        viewModel.setDestination(address: destination.subtitle, coordinate: destination.coordinate)
        if viewModel.pickupCoordinate == nil {
            viewModel.useCurrentLocation()
        }
        viewModel.calculateFare()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func centerMapOnUser() {
        // Center map animation would go here
    }

    private func zoomIn() {
        mapZoomLevel = max(0.01, mapZoomLevel * 0.5)
        updateMapRegion()
    }

    private func zoomOut() {
        mapZoomLevel = min(0.5, mapZoomLevel * 2.0)
        updateMapRegion()
    }

    private func updateMapRegion() {
        viewModel.mapRegion.span = MKCoordinateSpan(
            latitudeDelta: mapZoomLevel,
            longitudeDelta: mapZoomLevel
        )
    }
}

// MARK: - Supporting Views

struct QuickDestinationCard: View {
    let destination: QuickDestination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: destination.icon)
                    .font(.system(size: 24))
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.1))
                    )

                Text(destination.title)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .fontWeight(.medium)

                Text(destination.subtitle)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .lineLimit(2)
            }
            .frame(width: 140)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ComfortaDesign.Colors.surfaceSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentTripRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ComfortaDesign.Colors.surfaceSecondary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    Text(subtitle)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ComfortaDesign.Colors.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DriverCard: View {
    let driver: Driver

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(driver.name.prefix(1)))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(driver.name)
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)

                    Text(String(format: "%.1f", driver.rating))
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                FloatingMapButton(icon: "phone.fill", size: .small, style: .accent) {
                    // Call driver
                }

                FloatingMapButton(icon: "message.fill", size: .small, style: .white) {
                    // Message driver
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct TripStatusIndicator: View {
    let state: TripState

    var body: some View {
        HStack(spacing: 12) {
            if isLoadingState {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ComfortaDesign.Colors.primaryGreen))
            } else {
                Image(systemName: statusIconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(statusTint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state.displayName)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                if let detail = statusDetailText {
                    Text(detail)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
            )
    }

    private var isLoadingState: Bool {
        switch state {
        case .confirmingTrip, .processingPayment, .findingDriver:
            return true
        default:
            return false
        }
    }

    private var statusIconName: String {
        switch state {
        case .driverAssigned:
            return "person.crop.circle.fill"
        case .driverEnRoute:
            return "car.fill"
        case .driverArrived:
            return "location.circle.fill"
        case .inProgress:
            return "car.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        default:
            return "clock.fill"
        }
    }

    private var statusTint: Color {
        switch state {
        case .driverAssigned, .driverEnRoute, .driverArrived, .inProgress:
            return ComfortaDesign.Colors.primaryGreen
        case .completed:
            return ComfortaDesign.Colors.success
        case .cancelled:
            return ComfortaDesign.Colors.error
        default:
            return ComfortaDesign.Colors.textSecondary
        }
    }

    private var statusDetailText: String? {
        switch state {
        case .driverAssigned:
            return "Puedes contactar al conductor si lo necesitas."
        case .driverEnRoute:
            return "El conductor va en camino a tu recogida."
        case .driverArrived:
            return "Tu conductor ya está en el punto."
        case .inProgress:
            return "Disfruta el viaje. Te avisaremos al llegar."
        case .completed:
            return "Gracias por viajar con Comforta."
        case .cancelled:
            return "El viaje fue cancelado."
        default:
            return nil
        }
    }
}

private enum PendingStepStatus {
    case done
    case active
    case pending
}

private struct PendingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let status: PendingStepStatus
}

private struct TripDetailMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

private extension ProfessionalRideView {
    func pendingCopy(for state: TripState) -> (title: String, subtitle: String) {
        switch state {
        case .confirmingTrip:
            return ("Buscando conductor", "Estamos confirmando tu solicitud.")
        case .processingPayment:
            return ("Buscando conductor", "Estamos localizando al conductor más cercano.")
        case .findingDriver:
            return ("Buscando conductor", "Te avisaremos en cuanto esté asignado.")
        default:
            return ("Procesando", "Actualizando el estado de tu viaje.")
        }
    }

    func pendingIconName(for state: TripState) -> String {
        switch state {
        case .confirmingTrip:
            return "paperplane.fill"
        case .processingPayment:
            return "checkmark.seal.fill"
        case .findingDriver:
            return "person.2.fill"
        default:
            return "clock.fill"
        }
    }

    func pendingSteps(for state: TripState) -> [PendingStep] {
        let statuses: [PendingStepStatus]

        switch state {
        case .confirmingTrip:
            statuses = [.active, .pending, .pending]
        case .processingPayment:
            statuses = [.done, .active, .pending]
        case .findingDriver:
            statuses = [.done, .active, .pending]
        default:
            statuses = [.pending, .pending, .pending]
        }

        return [
            PendingStep(
                title: "Solicitud enviada",
                subtitle: "Recibimos los datos del viaje.",
                status: statuses[0]
            ),
            PendingStep(
                title: "Buscando conductor",
                subtitle: "Estamos localizando al conductor más cercano.",
                status: statuses[1]
            ),
            PendingStep(
                title: "Conductor confirmado",
                subtitle: "Llegará a la hora solicitada.",
                status: statuses[2]
            )
        ]
    }

    var tripDetailsCard: some View {
        let trip = viewModel.currentTrip
        let fareText = trip?.formattedFare ?? viewModel.summaryFareText
        let paymentText = trip?.paymentMethod.displayName ?? PaymentType.cash.displayName
        let distanceText = trip?.formattedDistance ?? (viewModel.estimatedDistance.isEmpty ? "—" : viewModel.estimatedDistance)
        let serviceTimeText = formattedServiceTime(for: trip?.scheduledAt ?? viewModel.requestedServiceDate)

        let metrics: [TripDetailMetric] = [
            TripDetailMetric(title: "Hora del servicio", value: serviceTimeText),
            TripDetailMetric(title: "Total estimado", value: fareText),
            TripDetailMetric(title: "Método de pago", value: paymentText),
            TripDetailMetric(title: "Distancia", value: distanceText)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Detalles del viaje")
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.title)
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Text(metric.value)
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ComfortaDesign.Colors.surface)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }

    func formattedServiceTime(for date: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none

        if calendar.isDateInToday(date) {
            return "Hoy, \(timeFormatter.string(from: date))"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }

    func pendingStepRow(_ step: PendingStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(pendingStepColor(step.status).opacity(step.status == .pending ? 0.15 : 0.25))
                    .frame(width: 28, height: 28)

                if step.status == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(pendingStepColor(step.status))
                } else if step.status == .active {
                    Circle()
                        .stroke(pendingStepColor(step.status), lineWidth: 2)
                        .frame(width: 16, height: 16)
                } else {
                    Circle()
                        .fill(pendingStepColor(step.status))
                        .frame(width: 8, height: 8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text(step.subtitle)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }

            Spacer()
        }
    }

    func pendingStepColor(_ status: PendingStepStatus) -> Color {
        switch status {
        case .done:
            return ComfortaDesign.Colors.primaryGreen
        case .active:
            return ComfortaDesign.Colors.accent
        case .pending:
            return ComfortaDesign.Colors.textTertiary
        }
    }
}

extension ProfessionalRideView {
    // MARK: - Map Selection Mode Functions

    private func enterMapSelectionMode() {
        guard viewModel.pickupCoordinate != nil else {
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isMapSelectionMode = true
            bottomSheetPosition = .peek
        }
    }

    private func handleMapTapAtCoordinate(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tempSelectedLocation = coordinate
            tempSelectedAddress = nil
            isLoadingAddress = true
        }

        Task {
            do {
                let geocoder = ReverseGeocodingService.shared
                let address = try await geocoder.reverseGeocode(coordinate: coordinate)

                await MainActor.run {
                    withAnimation {
                        tempSelectedAddress = address
                        isLoadingAddress = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        tempSelectedAddress = "Ubicación desconocida"
                        isLoadingAddress = false
                    }
                }
            }
        }
    }

    private func confirmDestination() {
        guard let location = tempSelectedLocation, let address = tempSelectedAddress else { return }

        viewModel.setDestination(address: address, coordinate: location)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isMapSelectionMode = false
            tempSelectedLocation = nil
            tempSelectedAddress = nil
            bottomSheetPosition = .middle
        }
    }

    private func cancelMapSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isMapSelectionMode = false
            tempSelectedLocation = nil
            tempSelectedAddress = nil
            isLoadingAddress = false
        }
    }

    // MARK: - Map Selection Overlays

    private var mapSelectionOverlay: some View {
        VStack {
            HStack {
                Button {
                    cancelMapSelection()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                        Text("Cancelar")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.6))
                    )
                }

                Spacer()

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16))
                        Text("Toca el mapa")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundColor(.white)

                    Text("Selecciona tu destino")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.6))
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()
        }
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
            .padding(.bottom, 150)
        }
    }

    private func confirmationPanel(address: String) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("Confirmar Destino")
                    .font(.headline.weight(.bold))

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

                HStack(spacing: 12) {
                    Button("Cancelar") {
                        cancelMapSelection()
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
                        confirmDestination()
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
    }
}

extension QuickDestination {
    var icon: String {
        switch title {
        case "Casa":
            return "house.fill"
        case "Trabajo":
            return "building.2.fill"
        case "Aeropuerto":
            return "airplane"
        default:
            return "mappin.circle.fill"
        }
    }
}

#Preview {
    ProfessionalRideView(
        userName: "Usuario Test",
        onLogout: {},
        onProfileTap: {}
    )
}
