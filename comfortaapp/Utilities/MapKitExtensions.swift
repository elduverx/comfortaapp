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

    static func regionToFit(
        coordinates: [CLLocationCoordinate2D],
        paddingFactor: Double = 1.3,
        minimumSpan: Double = 0.01
    ) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion()
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latitudeDelta = max((maxLat - minLat) * paddingFactor, minimumSpan)
        let longitudeDelta = max((maxLon - minLon) * paddingFactor, minimumSpan)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}

extension MKPolyline {
    func coordinatePoints() -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

extension MKMapRect {
    func padded(by scale: Double, minimumSize: Double = 2000) -> MKMapRect {
        let safeScale = max(scale, 1.0)
        let width = max(size.width, minimumSize)
        let height = max(size.height, minimumSize)
        let baseRect = MKMapRect(
            x: midX - width / 2,
            y: midY - height / 2,
            width: width,
            height: height
        )

        let dx = baseRect.size.width * (safeScale - 1) / 2
        let dy = baseRect.size.height * (safeScale - 1) / 2
        return baseRect.insetBy(dx: -dx, dy: -dy)
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

public extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
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
