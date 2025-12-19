import MapKit
import CoreLocation

// MARK: - MapKit Extensions

extension MKCoordinateRegion {
    init(_ rect: MKMapRect) {
        let topLeft = MKMapPoint(x: rect.minX, y: rect.minY)
        let bottomRight = MKMapPoint(x: rect.maxX, y: rect.maxY)
        
        let topLeftCoord = topLeft.coordinate
        let bottomRightCoord = bottomRight.coordinate
        
        let center = CLLocationCoordinate2D(
            latitude: (topLeftCoord.latitude + bottomRightCoord.latitude) / 2,
            longitude: (topLeftCoord.longitude + bottomRightCoord.longitude) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude),
            longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude)
        )
        
        self.init(center: center, span: span)
    }
}

extension MKPolyline {
    func coordinatePoints() -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return abs(lhs.latitude - rhs.latitude) < 0.0001 && 
               abs(lhs.longitude - rhs.longitude) < 0.0001
    }
}

extension CLLocationDistance {
    var formattedDistance: String {
        if self < 1000 {
            return String(format: "%.0f m", self)
        } else {
            return String(format: "%.1f km", self / 1000)
        }
    }
}

extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Valencia Region Helper

struct ValenciaRegion {
    static let center = CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763)
    static let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    static let region = MKCoordinateRegion(center: center, span: span)
    
    static func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latRange = (center.latitude - span.latitudeDelta/2)...(center.latitude + span.latitudeDelta/2)
        let lonRange = (center.longitude - span.longitudeDelta/2)...(center.longitude + span.longitudeDelta/2)
        
        return latRange.contains(coordinate.latitude) && lonRange.contains(coordinate.longitude)
    }
}