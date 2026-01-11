import SwiftUI
import CoreLocation
import MapKit

struct TripSummaryCard: View {
    let trip: Trip?
    let onCurrentLocationTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let trip = trip {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Resumen del viaje")
                            .font(.headline.weight(.semibold))
                        Spacer()
                        Button("Usar ubicación actual", action: onCurrentLocationTapped)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    TripDetailsRow(
                        icon: "mappin.circle.fill",
                        title: "Recogida",
                        subtitle: trip.pickupLocation.address,
                        iconColor: .green
                    )
                    
                    TripDetailsRow(
                        icon: "flag.checkered",
                        title: "Destino",
                        subtitle: trip.destinationLocation.address,
                        iconColor: .accentColor
                    )
                    
                    Divider()
                    
                    HStack {
                        TripMetric(
                            icon: "ruler",
                            title: "Distancia",
                            value: trip.formattedDistance
                        )
                        
                        Spacer()
                        
                        TripMetric(
                            icon: "clock",
                            title: "Tiempo est.",
                            value: trip.formattedDuration
                        )
                        
                        Spacer()
                        
                        TripMetric(
                            icon: "eurosign.circle.fill",
                            title: "Precio",
                            value: trip.formattedFare,
                            isHighlighted: true
                        )
                    }
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("Planifica tu viaje")
                            .font(.headline.weight(.semibold))
                        Spacer()
                        Button("Usar ubicación actual", action: onCurrentLocationTapped)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("Selecciona los puntos de recogida y destino para ver el precio estimado")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

private struct TripDetailsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

private struct TripMetric: View {
    let icon: String
    let title: String
    let value: String
    let isHighlighted: Bool
    
    init(icon: String, title: String, value: String, isHighlighted: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isHighlighted ? .accentColor : .secondary)
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isHighlighted ? .accentColor : .primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TripSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        let samplePickup = LocationInfo(
            address: "Plaza Mayor, Madrid, España",
            coordinate: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038)
        )
        
        let sampleDestination = LocationInfo(
            address: "Aeropuerto Madrid-Barajas, Madrid, España",
            coordinate: CLLocationCoordinate2D(latitude: 40.3838, longitude: -3.7186)
        )
        
        let samplePayment = PaymentMethodInfo(
            type: .cash,
            displayName: "Efectivo",
            isDefault: true
        )
        
        let sampleTrip = Trip(
            userId: "user123",
            pickupLocation: samplePickup,
            destinationLocation: sampleDestination,
            estimatedFare: 23.13,
            estimatedDistance: 15.42,
            estimatedDuration: 1800,
            vehicleType: "Standard",
            paymentMethod: samplePayment
        )
        
        VStack(spacing: 20) {
            TripSummaryCard(trip: sampleTrip, onCurrentLocationTapped: {})
            TripSummaryCard(trip: nil, onCurrentLocationTapped: {})
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
