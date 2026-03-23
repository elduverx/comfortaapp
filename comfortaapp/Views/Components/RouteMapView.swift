import SwiftUI
import MapKit

struct RouteMapAnnotation: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let tint: Color
}

struct RouteMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [RouteMapAnnotation]
    let route: MKPolyline?
    let showsUserLocation: Bool

    init(
        region: Binding<MKCoordinateRegion>,
        annotations: [RouteMapAnnotation],
        route: MKPolyline?,
        showsUserLocation: Bool = true
    ) {
        self._region = region
        self.annotations = annotations
        self.route = route
        self.showsUserLocation = showsUserLocation
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.showsUserLocation = showsUserLocation

        if !regionsEqual(mapView.region, region) {
            context.coordinator.isProgrammaticRegionChange = true
            mapView.setRegion(region, animated: true)
        }

        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        let newAnnotations = annotations.map { RouteAnnotation(from: $0) }
        mapView.addAnnotations(newAnnotations)

        mapView.removeOverlays(mapView.overlays)
        if let route = route {
            mapView.addOverlay(route)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func regionsEqual(_ lhs: MKCoordinateRegion, _ rhs: MKCoordinateRegion) -> Bool {
        let centerLatDiff = abs(lhs.center.latitude - rhs.center.latitude)
        let centerLonDiff = abs(lhs.center.longitude - rhs.center.longitude)
        let spanLatDiff = abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta)
        let spanLonDiff = abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta)

        return centerLatDiff < 0.0001 &&
            centerLonDiff < 0.0001 &&
            spanLatDiff < 0.0001 &&
            spanLonDiff < 0.0001
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        var isProgrammaticRegionChange = false

        init(parent: RouteMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isProgrammaticRegionChange {
                isProgrammaticRegionChange = false
                return
            }
            let newRegion = mapView.region
            if parent.regionsEqual(newRegion, parent.region) {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.parent.region = newRegion
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(ComfortaDesign.Colors.primaryGreen)
                renderer.lineWidth = 5
                renderer.lineJoin = .round
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            let identifier = "route-annotation"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView)
                ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true

            if let routeAnnotation = annotation as? RouteAnnotation {
                view.pinTintColor = routeAnnotation.tint
            } else {
                view.pinTintColor = UIColor(ComfortaDesign.Colors.primaryGreen)
            }

            return view
        }
    }
}

private final class RouteAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let tint: UIColor

    init(coordinate: CLLocationCoordinate2D, title: String, tint: UIColor) {
        self.coordinate = coordinate
        self.title = title
        self.tint = tint
        super.init()
    }

    convenience init(from annotation: RouteMapAnnotation) {
        self.init(
            coordinate: annotation.coordinate,
            title: annotation.title,
            tint: UIColor(annotation.tint)
        )
    }
}
