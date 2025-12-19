import SwiftUI
import MapKit
import Combine
import CoreLocation

struct InteractiveMapView: View {
    let origin: String
    let destination: String
    
    @State private var route: MKRoute?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position) {
            // Marcador de origen
            if let originCoord = originCoordinate {
                Marker("Recogida", systemImage: "location.fill", coordinate: originCoord)
                    .tint(.green)
            }
            
            // Marcador de destino
            if let destCoord = destinationCoordinate {
                Marker("Destino", systemImage: "mappin.circle.fill", coordinate: destCoord)
                    .tint(.red)
            }
            
            // Línea de ruta
            if let route = route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .task {
            await loadRoute()
        }
    }
    
    @State private var originCoordinate: CLLocationCoordinate2D?
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    
    private func loadRoute() async {
        do {
            let geocoder = GeocodingService()
            originCoordinate = try await geocoder.geocodeAddress(origin)
            destinationCoordinate = try await geocoder.geocodeAddress(destination)
            
            guard let orig = originCoordinate, let dest = destinationCoordinate else { return }
            
            let routeService = RouteService()
            let routeInfo = try await routeService.calculateRoute(from: orig, to: dest)
            
            await MainActor.run {
                route = routeInfo.route
                
                // Centrar cámara en la ruta
                let rect = routeInfo.route.polyline.boundingMapRect
                position = .rect(rect)
            }
        } catch {
            print("Error: \(error)")
        }
    }
}