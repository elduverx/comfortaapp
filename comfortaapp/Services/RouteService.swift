import MapKit
import CoreLocation

class RouteService {
    
    struct RouteInfo {
        let distance: Double // en kilómetros
        let duration: TimeInterval // en segundos
        let route: MKRoute
    }
    
    // Calcular ruta entre dos direcciones
    func calculateRoute(from origin: String, to destination: String) async throws -> RouteInfo {
        let geocoder = GeocodingService()
        
        // Convertir direcciones a coordenadas
        let originCoordinate = try await geocoder.geocodeAddress(origin)
        let destinationCoordinate = try await geocoder.geocodeAddress(destination)
        
        // Calcular ruta
        return try await calculateRoute(
            from: originCoordinate,
            to: destinationCoordinate
        )
    }
    
    // Calcular ruta entre dos coordenadas
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteInfo {
        
        let originPlacemark = MKPlacemark(coordinate: origin)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: originPlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw RouteError.noRouteFound
        }
        
        return RouteInfo(
            distance: route.distance / 1000, // metros a kilómetros
            duration: route.expectedTravelTime,
            route: route
        )
    }
}

enum RouteError: Error {
    case noRouteFound
    case invalidCoordinates
}