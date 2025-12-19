import SwiftUI
import MapKit
import Combine
import CoreLocation

struct MapPreviewView: View {
    let origin: String
    let destination: String
    
    @State private var route: MKRoute?
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                Map(position: .constant(.region(mapRegion))) {
                    // Marcadores
                    ForEach(annotations) { annotation in
                        Marker(annotation.id, systemImage: "mappin.circle.fill", coordinate: annotation.coordinate)
                            .tint(annotation.tint)
                    }
                    
                    // Línea de ruta
                    if let route = route {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 3)
                    }
                }
                .disabled(true)
            } else {
                Map(coordinateRegion: $mapRegion, annotationItems: annotations) { annotation in
                    MapPin(coordinate: annotation.coordinate, tint: annotation.tint)
                }
                .disabled(true)
            }
            
            if isLoading {
                ProgressView()
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
        }
        .task {
            await loadRoute()
        }
    }
    
    @State private var originCoordinate: CLLocationCoordinate2D?
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    
    private var annotations: [PreviewMapAnnotation] {
        var results: [PreviewMapAnnotation] = []
        
        if let origin = originCoordinate {
            results.append(PreviewMapAnnotation(id: "origin", coordinate: origin, tint: .green))
        }
        
        if let destination = destinationCoordinate {
            results.append(PreviewMapAnnotation(id: "destination", coordinate: destination, tint: .red))
        }
        
        return results
    }
    
    private func loadRoute() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let geocoder = GeocodingService()
            let originCoord = try await geocoder.geocodeAddress(origin)
            let destinationCoord = try await geocoder.geocodeAddress(destination)
            
            let routeService = RouteService()
            let routeInfo = try await routeService.calculateRoute(from: originCoord, to: destinationCoord)
            
            await MainActor.run {
                self.originCoordinate = originCoord
                self.destinationCoordinate = destinationCoord
                self.route = routeInfo.route
                
                // Ajustar región del mapa para mostrar toda la ruta
                let rect = routeInfo.route.polyline.boundingMapRect
                let region = MKCoordinateRegion(rect)
                
                // Agregar padding
                mapRegion = MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(
                        latitudeDelta: region.span.latitudeDelta * 1.3,
                        longitudeDelta: region.span.longitudeDelta * 1.3
                    )
                )
            }
        } catch {
            print("Error cargando ruta: \(error)")
        }
    }
}

struct PreviewMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let tint: Color
}