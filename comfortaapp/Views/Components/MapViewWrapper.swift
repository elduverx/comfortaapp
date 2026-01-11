import SwiftUI
import MapKit
import CoreLocation

struct MapViewWrapper: View {
    @Binding var region: MKCoordinateRegion
    let trip: Trip?
    let currentLocation: CLLocation?
    
    var body: some View {
        Map(coordinateRegion: $region, 
            showsUserLocation: true,
            annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                AnnotationView(
                    type: annotation.type,
                    title: annotation.title
                )
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .onAppear {
            configureMapRegion()
        }
        .onChange(of: trip) { _ in
            configureMapRegion()
        }
    }
    
    private var annotations: [WrapperMapAnnotationItem] {
        guard let trip = trip else { return [] }
        
        return [
            WrapperMapAnnotationItem(
                coordinate: trip.pickupLocation.coordinate.clLocationCoordinate,
                type: .pickup,
                title: trip.pickupLocation.address
            ),
            WrapperMapAnnotationItem(
                coordinate: trip.destinationLocation.coordinate.clLocationCoordinate,
                type: .destination,
                title: trip.destinationLocation.address
            )
        ]
    }
    
    private func configureMapRegion() {
        guard let trip = trip else {
            // If no trip, center on current location or default
            if let currentLocation = currentLocation {
                region.center = currentLocation.coordinate
            }
            return
        }
        
        // Calculate region to show both pickup and destination
        let coordinates = [trip.pickupLocation.coordinate.clLocationCoordinate, trip.destinationLocation.coordinate.clLocationCoordinate]
        let rect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let point = MKMapPoint(coordinate)
            let pointRect = MKMapRect(
                x: point.x - 1000,
                y: point.y - 1000,
                width: 2000,
                height: 2000
            )
            return rect.union(pointRect)
        }
        
        region = MKCoordinateRegion(rect.insetBy(dx: -rect.size.width * 0.3, dy: -rect.size.height * 0.3))
    }
}

private struct WrapperMapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    let title: String
}

private enum AnnotationType {
    case pickup
    case destination
    
    var color: Color {
        switch self {
        case .pickup: return .green
        case .destination: return .accentColor
        }
    }
    
    var icon: String {
        switch self {
        case .pickup: return "mappin.circle.fill"
        case .destination: return "flag.fill"
        }
    }
}

private struct AnnotationView: View {
    let type: AnnotationType
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(type.color)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
    }
}

struct MapViewWrapper_Previews: PreviewProvider {
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
        
        MapViewWrapper(
            region: .constant(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )),
            trip: sampleTrip,
            currentLocation: nil
        )
    }
}
