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
    
    private var annotations: [MapAnnotationItem] {
        guard let trip = trip else { return [] }
        
        return [
            MapAnnotationItem(
                coordinate: trip.pickup.coordinate,
                type: .pickup,
                title: trip.pickup.name ?? "Recogida"
            ),
            MapAnnotationItem(
                coordinate: trip.destination.coordinate,
                type: .destination,
                title: trip.destination.name ?? "Destino"
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
        let coordinates = [trip.pickup.coordinate, trip.destination.coordinate]
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

private struct MapAnnotationItem: Identifiable {
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
        let samplePickup = LocationPoint(
            coordinate: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            address: "Plaza Mayor, Madrid, España",
            name: "Plaza Mayor"
        )
        
        let sampleDestination = LocationPoint(
            coordinate: CLLocationCoordinate2D(latitude: 40.3838, longitude: -3.7186),
            address: "Aeropuerto Madrid-Barajas, Madrid, España",
            name: "Aeropuerto"
        )
        
        let sampleTrip = Trip(
            pickup: samplePickup,
            destination: sampleDestination,
            distance: 15420,
            estimatedFare: 23.13,
            estimatedDuration: 1800,
            status: .planning,
            createdAt: Date()
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