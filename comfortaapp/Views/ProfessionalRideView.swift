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

    let userName: String
    let onLogout: () -> Void

    init(userName: String, onLogout: @escaping () -> Void) {
        self.userName = userName
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack {
            // Full Screen Map
            mapView

            // Floating Controls Overlay
            floatingControls

            // Bottom Sheet with Search and Details
            BottomSheet(position: $bottomSheetPosition, backgroundColor: ComfortaDesign.Colors.surface) {
                bottomSheetContent
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            if !hasTrackedHome {
                AnalyticsService.shared.track(.viewHome)
                hasTrackedHome = true
            }
            viewModel.useCurrentLocation()
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

    // MARK: - Map View

    private var mapView: some View {
        Map(
            coordinateRegion: $viewModel.mapRegion,
            showsUserLocation: true,
            annotationItems: mapAnnotations
        ) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                ModernMapPin(type: annotation.type, title: annotation.title)
            }
        }
        .overlay(routeOverlay)
        .onTapGesture {
            hideKeyboard()
        }
    }

    @ViewBuilder
    private var routeOverlay: some View {
        if let polyline = viewModel.routePolyline {
            RouteOverlayView(polyline: polyline, region: viewModel.mapRegion)
        }
    }

    // MARK: - Floating Controls

    private var floatingControls: some View {
        VStack {
            // Top Bar
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 50)

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
                onLogout()
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
        case .driverAssigned, .driverEnRoute, .driverArrived, .inProgress:
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
                searchField(
                    text: $viewModel.pickupText,
                    placeholder: "Ubicación actual",
                    icon: "circle.fill",
                    iconColor: ComfortaDesign.Colors.primaryGreen,
                    onCurrentLocation: {
                        viewModel.useCurrentLocation()
                    }
                )

                Divider()
                    .padding(.leading, 52)

                searchField(
                    text: $viewModel.destinationText,
                    placeholder: "¿A dónde vas?",
                    icon: "mappin.circle.fill",
                    iconColor: ComfortaDesign.Colors.error,
                    onSelection: { address, coordinate in
                        viewModel.setDestination(address: address, coordinate: coordinate)
                        bottomSheetPosition = .middle
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
                        value: viewModel.estimatedFare
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
                viewModel.confirmTrip()
                showingTripConfirmation = true
            }
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

            Spacer()
        }
    }

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recientes")
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .padding(.horizontal, 20)

            ForEach(0..<3, id: \.self) { _ in
                RecentTripRow(
                    title: "Casa",
                    subtitle: "Av. del Puerto 22, Valencia",
                    icon: "house.fill"
                ) {
                    // Select recent trip
                }
            }
        }
    }

    // MARK: - Helper Views

    private func searchField(
        text: Binding<String>,
        placeholder: String,
        icon: String,
        iconColor: Color,
        onCurrentLocation: (() -> Void)? = nil,
        onSelection: ((String, CLLocationCoordinate2D) -> Void)? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            if let onCurrentLocation = onCurrentLocation, text.wrappedValue.isEmpty {
                Button(action: onCurrentLocation) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
            }
        }
    }

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
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ComfortaDesign.Colors.primaryGreen))

            Text(state.displayName)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
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
    ProfessionalRideView(userName: "Usuario Test", onLogout: {})
}
