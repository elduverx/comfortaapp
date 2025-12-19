import Foundation
import CoreLocation
import Combine
import MapKit

public final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var isLocationAvailable: Bool = false
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        setupLocationManager()
        bindLocationAvailability()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func bindLocationAvailability() {
        $authorizationStatus
            .map { status in
                status == .authorizedWhenInUse || status == .authorizedAlways
            }
            .assign(to: \.isLocationAvailable, on: self)
            .store(in: &cancellables)
    }
    
    public func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Los permisos de ubicación están desactivados. Ve a Ajustes para habilitarlos."
        default:
            break
        }
    }
    
    public func requestLocation() {
        guard isLocationAvailable else {
            requestPermission()
            return
        }
        
        errorMessage = nil
        locationManager.requestLocation()
    }
    
    public func startUpdatingLocation() {
        guard isLocationAvailable else {
            requestPermission()
            return
        }
        
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            if self.isLocationAvailable {
                self.errorMessage = nil
            } else if self.authorizationStatus == .denied || self.authorizationStatus == .restricted {
                self.errorMessage = "Los permisos de ubicación están desactivados."
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.errorMessage = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.errorMessage = "Acceso a ubicación denegado."
                case .locationUnknown:
                    self.errorMessage = "No se pudo determinar la ubicación."
                case .network:
                    self.errorMessage = "Error de red al obtener ubicación."
                default:
                    self.errorMessage = "Error al obtener ubicación: \(clError.localizedDescription)"
                }
            } else {
                self.errorMessage = "Error inesperado: \(error.localizedDescription)"
            }
        }
    }
}
