import SwiftUI
import CoreLocation

struct TripConfirmationView: View {
    let trip: Trip
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.lg) {
                // Header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    
                    Text("Confirmar Viaje")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Spacer()
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                // Trip Details
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    TripDetailRow(
                        icon: "location.circle.fill",
                        label: "Origen",
                        value: trip.pickupLocation.address,
                        iconColor: ComfortaDesign.Colors.primaryGreen
                    )
                    
                    TripDetailRow(
                        icon: "flag.checkered",
                        label: "Destino", 
                        value: trip.destinationLocation.address,
                        iconColor: ComfortaDesign.Colors.error
                    )

                    TripDetailRow(
                        icon: "calendar",
                        label: "Hora del servicio",
                        value: serviceTimeText,
                        iconColor: ComfortaDesign.Colors.textSecondary
                    )
                    
                    TripDetailRow(
                        icon: "ruler",
                        label: "Distancia",
                        value: trip.formattedDistance,
                        iconColor: ComfortaDesign.Colors.textSecondary
                    )
                    
                    TripDetailRow(
                        icon: "clock.fill",
                        label: "Duración",
                        value: trip.formattedDuration,
                        iconColor: ComfortaDesign.Colors.textSecondary
                    )
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                // Price Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Precio del Viaje")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        
                        Text(trip.formattedFare)
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Pago")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: trip.paymentMethod.type.iconName)
                                .font(.caption)
                            Text(trip.paymentMethod.displayName)
                                .font(ComfortaDesign.Typography.caption1)
                        }
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    }
                }
                .padding(.vertical, ComfortaDesign.Spacing.sm)
                .padding(.horizontal, ComfortaDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .fill(ComfortaDesign.Colors.surfaceSecondary.opacity(0.5))
                )
                
                // Payment Disabled Notice
                HStack(spacing: ComfortaDesign.Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(ComfortaDesign.Colors.warning)
                    
                    Text("Los pagos están temporalmente deshabilitados. El viaje se procesará sin cargo.")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
                .padding(ComfortaDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .fill(ComfortaDesign.Colors.warning.opacity(0.1))
                )
                
                // Action Buttons
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Button(action: onCancel) {
                        Text("Cancelar")
                            .font(ComfortaDesign.Typography.button)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                                    .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    LiquidButton(
                        "Confirmar Viaje",
                        icon: "checkmark.circle.fill",
                        style: .primary,
                        size: .medium,
                        action: onConfirm
                    )
                }
            }
        }
    }
}

struct TripDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(label)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .lineLimit(2)
        }
    }
}

private extension TripConfirmationView {
    var serviceTimeText: String {
        guard let date = trip.scheduledAt else { return "Ahora" }
        return formattedServiceTime(for: date)
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
}

struct DriverAssignedView: View {
    let driver: Driver
    let trip: Trip
    let onContinue: () -> Void
    
    var body: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.lg) {
                // Success Header
                VStack(spacing: ComfortaDesign.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    
                    Text("¡Conductor Asignado!")
                        .font(ComfortaDesign.Typography.title2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tu conductor está en camino")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                // Driver Info
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    // Driver Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(driver.name.prefix(1)))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver.name)
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: index < Int(driver.rating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(index < Int(driver.rating) ? .yellow : ComfortaDesign.Colors.textSecondary)
                            }
                            Text(String(format: "%.1f", driver.rating))
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        Text("\(driver.totalTrips) viajes completados")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Contact Buttons
                    VStack(spacing: 8) {
                        Button(action: {
                            // Call driver
                        }) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(ComfortaDesign.Colors.primaryGreen)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Message driver
                        }) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(ComfortaDesign.Colors.primaryGreen)
                                .clipShape(Circle())
                        }
                    }
                }
                
                // Vehicle Info
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    Text("Vehículo")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(driver.vehicleInfo.color) \(driver.vehicleInfo.make) \(driver.vehicleInfo.model)")
                                .font(ComfortaDesign.Typography.body1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            
                            Text("Año: \(driver.vehicleInfo.year)")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(driver.vehicleInfo.licensePlate)
                            .font(ComfortaDesign.Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                }
                .padding(ComfortaDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .fill(ComfortaDesign.Colors.surfaceSecondary.opacity(0.5))
                )
                
                // Trip Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tiempo estimado de llegada")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        
                        Text("5-8 minutos")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Precio")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        
                        Text(trip.formattedFare)
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    }
                }
                
                // Continue Button
                LiquidButton(
                    "Seguir viaje",
                    icon: "arrow.forward.circle.fill",
                    style: .primary,
                    size: .medium,
                    action: onContinue
                )
            }
        }
    }
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
    
    let mockDriver = Driver(
        userId: "driver123",
        licenseNumber: "ES123456789",
        name: "Carlos Rodríguez",
        vehicleInfo: VehicleInfo(
            make: "Tesla",
            model: "Model Y",
            year: 2023,
            color: "Blanco",
            licensePlate: "ABC1234",
            capacity: 4,
            vehicleType: .sedan
        )
    )
    
    VStack(spacing: 20) {
        TripConfirmationView(
            trip: mockTrip,
            onConfirm: {},
            onCancel: {}
        )
        
        DriverAssignedView(
            driver: mockDriver,
            trip: mockTrip,
            onContinue: {}
        )
    }
    .padding()
    .background(ComfortaDesign.Colors.background)
}
