import SwiftUI
import MapKit
import CoreLocation
import UIKit

/// Mapa interactivo profesional con UIKit para captura precisa de taps
struct InteractiveTapMapView: UIViewRepresentable {

    // MARK: - Bindings
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?

    // MARK: - Properties
    let region: MKCoordinateRegion
    let pickupLocation: CLLocationCoordinate2D?
    let showPickupPin: Bool
    let onLocationSelected: ((CLLocationCoordinate2D) -> Void)?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)

        // Configuración del mapa
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true

        // Gesture recognizer para taps
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)

        // Agregar pins iniciales
        context.coordinator.updateAnnotations(
            mapView: mapView,
            pickup: pickupLocation,
            destination: selectedCoordinate,
            showPickup: showPickupPin
        )

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateAnnotations(
            mapView: mapView,
            pickup: pickupLocation,
            destination: selectedCoordinate,
            showPickup: showPickupPin
        )

        // Actualizar región si hay pickup y destino
        if let pickup = pickupLocation, let destination = selectedCoordinate {
            let updatedRegion = MKCoordinateRegion.regionToFit(
                coordinates: [pickup, destination],
                paddingFactor: 1.5,
                minimumSpan: 0.01
            )
            mapView.setRegion(updatedRegion, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            selectedCoordinate: $selectedCoordinate,
            selectedAddress: $selectedAddress,
            onLocationSelected: onLocationSelected
        )
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var selectedCoordinate: CLLocationCoordinate2D?
        @Binding var selectedAddress: String?
        let onLocationSelected: ((CLLocationCoordinate2D) -> Void)?

        private let geocodingService = ReverseGeocodingService.shared

        init(
            selectedCoordinate: Binding<CLLocationCoordinate2D?>,
            selectedAddress: Binding<String?>,
            onLocationSelected: ((CLLocationCoordinate2D) -> Void)?
        ) {
            self._selectedCoordinate = selectedCoordinate
            self._selectedAddress = selectedAddress
            self.onLocationSelected = onLocationSelected
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }

            // No permitir seleccionar si ya hay destino
            guard selectedCoordinate == nil else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // Feedback háptico
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Actualizar coordenada seleccionada
            Task { @MainActor in
                selectedCoordinate = coordinate
                onLocationSelected?(coordinate)

                // Obtener dirección
                do {
                    let address = try await geocodingService.reverseGeocode(coordinate: coordinate)
                    selectedAddress = address
                } catch {
                    selectedAddress = "Ubicación desconocida"
                    print("Error al obtener dirección: \(error)")
                }

                // Actualizar anotaciones
                updateAnnotations(
                    mapView: mapView,
                    pickup: nil,
                    destination: coordinate,
                    showPickup: true
                )
            }
        }

        func updateAnnotations(
            mapView: MKMapView,
            pickup: CLLocationCoordinate2D?,
            destination: CLLocationCoordinate2D?,
            showPickup: Bool
        ) {
            // Remover anotaciones existentes
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })

            // Agregar pin de pickup
            if showPickup, let pickup = pickup {
                let pickupAnnotation = CustomMapAnnotation(
                    coordinate: pickup,
                    title: "Recogida",
                    subtitle: nil,
                    type: .pickup
                )
                mapView.addAnnotation(pickupAnnotation)
            }

            // Agregar pin de destino
            if let destination = destination {
                let destinationAnnotation = CustomMapAnnotation(
                    coordinate: destination,
                    title: "Destino",
                    subtitle: selectedAddress,
                    type: .destination
                )
                mapView.addAnnotation(destinationAnnotation)
            }
        }

        // MARK: - MKMapViewDelegate

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let customAnnotation = annotation as? CustomMapAnnotation else {
                return nil
            }

            let identifier = "CustomPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // Configurar apariencia según el tipo
            switch customAnnotation.annotationType {
            case .pickup:
                annotationView?.markerTintColor = .systemGreen
                annotationView?.glyphImage = UIImage(systemName: "figure.walk.circle.fill")
            case .destination:
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphImage = UIImage(systemName: "flag.fill")
                annotationView?.animatesWhenAdded = true
            case .driver:
                annotationView?.markerTintColor = .systemPurple
                annotationView?.glyphImage = UIImage(systemName: "car.fill")
            }

            return annotationView
        }
    }
}

// MARK: - Custom Annotation

class CustomMapAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let annotationType: AnnotationTypeMap

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, type: AnnotationTypeMap) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.annotationType = type
    }
}

enum AnnotationTypeMap {
    case pickup
    case destination
    case driver
}

// MARK: - Preview

struct InteractiveTapMapView_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveTapMapViewPreviewContainer()
    }
}

private struct InteractiveTapMapViewPreviewContainer: View {
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String?

    var body: some View {
        VStack {
            InteractiveTapMapView(
                selectedCoordinate: $selectedCoordinate,
                selectedAddress: $selectedAddress,
                region: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ),
                pickupLocation: CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
                showPickupPin: true,
                onLocationSelected: { coordinate in
                    print("📍 Coordenadas seleccionadas: \(coordinate.latitude), \(coordinate.longitude)")
                }
            )

            if let address = selectedAddress {
                Text("Seleccionado: \(address)")
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
}
