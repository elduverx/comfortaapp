import SwiftUI
import MapKit

struct TripDetailsView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @State private var mapRegion: MKCoordinateRegion
    
    init(trip: Trip) {
        self.trip = trip
        
        // Calculate map region to show both pickup and destination
        let pickup = trip.pickupLocation.coordinate
        let destination = trip.destinationLocation.coordinate
        
        let centerLat = (pickup.latitude + destination.latitude) / 2
        let centerLon = (pickup.longitude + destination.longitude) / 2
        
        let latDelta = abs(pickup.latitude - destination.latitude) * 1.5
        let lonDelta = abs(pickup.longitude - destination.longitude) * 1.5
        
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ComfortaDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                        // Map Section
                        mapSection
                        
                        // Trip Status
                        statusSection
                        
                        // Route Information
                        routeSection
                        
                        // Trip Details
                        detailsSection
                        
                        // Driver Information (if available)
                        if trip.status == .completed || trip.status == .inProgress {
                            driverSection
                        }
                        
                        // Payment Information
                        paymentSection
                        
                        // Actions
                        actionsSection
                    }
                    .padding(.horizontal, ComfortaDesign.Spacing.lg)
                    .padding(.top, ComfortaDesign.Spacing.md)
                }
            }
            .navigationTitle("Detalles del Viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var mapSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: 0) {
                Map(coordinateRegion: .constant(mapRegion), annotationItems: mapAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        Circle()
                            .fill(annotation.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(radius: 4)
                    }
                }
                .frame(height: 200)
                .cornerRadius(ComfortaDesign.Radius.md)
                .allowsHitTesting(false)
            }
        }
    }
    
    private var statusSection: some View {
        ModernCard(style: .glass) {
            HStack {
                Circle()
                    .fill(trip.status.color)
                    .frame(width: 12, height: 12)
                
                Text(trip.status.displayName)
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(trip.status.color)
                
                Spacer()
                
                Text(formatDate(trip.dateCreated))
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
        }
    }
    
    private var routeSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Ruta")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    RoutePoint(
                        icon: "location.circle.fill",
                        iconColor: ComfortaDesign.Colors.primaryGreen,
                        title: "Origen",
                        address: trip.pickupLocation.address
                    )
                    
                    // Route line
                    HStack {
                        VStack {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(ComfortaDesign.Colors.textTertiary)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    RoutePoint(
                        icon: "flag.checkered",
                        iconColor: ComfortaDesign.Colors.error,
                        title: "Destino",
                        address: trip.destinationLocation.address
                    )
                }
            }
        }
    }
    
    private var detailsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Información del Viaje")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    DetailItem(
                        icon: "eurosign.circle.fill",
                        title: "Precio",
                        value: trip.formattedFare,
                        color: ComfortaDesign.Colors.primaryGreen
                    )
                    
                    DetailItem(
                        icon: "ruler",
                        title: "Distancia",
                        value: trip.formattedDistance,
                        color: ComfortaDesign.Colors.accent
                    )
                    
                    DetailItem(
                        icon: "clock.fill",
                        title: "Duración",
                        value: trip.formattedDuration,
                        color: ComfortaDesign.Colors.warning
                    )
                    
                    DetailItem(
                        icon: "car.fill",
                        title: "Tipo",
                        value: trip.vehicleType,
                        color: ComfortaDesign.Colors.textSecondary
                    )
                }
            }
        }
    }
    
    private var driverSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Conductor")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("CR")
                                .font(ComfortaDesign.Typography.body1)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Carlos Rodríguez")
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: index < 5 ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundColor(index < 5 ? .yellow : ComfortaDesign.Colors.textTertiary)
                            }
                            Text("4.9")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        Text("Tesla Model Y - Blanco")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button(action: {}) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(ComfortaDesign.Colors.primaryGreen)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(ComfortaDesign.Colors.accent)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
    }
    
    private var paymentSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Información de Pago")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                HStack {
                    Image(systemName: trip.paymentMethod.type.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.paymentMethod.displayName)
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("Pagado el \(formatDate(trip.dateCreated))")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(trip.formattedFare)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: ComfortaDesign.Spacing.md) {
            if trip.status == .completed {
                LiquidButton(
                    "Repetir Viaje",
                    icon: "arrow.clockwise.circle.fill",
                    style: .primary,
                    size: .medium,
                    action: {
                        // Repeat trip action
                    }
                )
                
                LiquidButton(
                    "Calificar Viaje",
                    icon: "star.fill",
                    style: .secondary,
                    size: .medium,
                    action: {
                        // Rate trip action
                    }
                )
            }
            
            LiquidButton(
                "Obtener Recibo",
                icon: "doc.fill",
                style: .glass,
                size: .medium,
                action: {
                    // Get receipt action
                }
            )
        }
    }
    
    // MARK: - Helper Properties
    
    private var mapAnnotations: [MapAnnotationItem] {
        let pickupCoordinate = CLLocationCoordinate2D(
            latitude: trip.pickupLocation.coordinate.latitude,
            longitude: trip.pickupLocation.coordinate.longitude
        )
        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: trip.destinationLocation.coordinate.latitude,
            longitude: trip.destinationLocation.coordinate.longitude
        )
        
        return [
            MapAnnotationItem(
                coordinate: pickupCoordinate,
                color: ComfortaDesign.Colors.primaryGreen
            ),
            MapAnnotationItem(
                coordinate: destinationCoordinate,
                color: ComfortaDesign.Colors.error
            )
        ]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RoutePoint: View {
    let icon: String
    let iconColor: Color
    let title: String
    let address: String
    
    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                
                Text(address)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(ComfortaDesign.Typography.title3)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ComfortaDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.sm)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let color: Color
}

#Preview {
    let mockTrip = Trip(
        userId: "user123",
        pickupLocation: LocationInfo(
            address: "Plaza Mayor, Madrid",
            coordinate: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038)
        ),
        destinationLocation: LocationInfo(
            address: "Aeropuerto Madrid-Barajas",
            coordinate: CLLocationCoordinate2D(latitude: 40.4839, longitude: -3.5680)
        ),
        estimatedFare: 35.50,
        estimatedDistance: 25.3,
        estimatedDuration: 1800,
        vehicleType: "Standard",
        paymentMethod: PaymentMethodInfo(type: .cash)
    )
    
    TripDetailsView(trip: mockTrip)
}
