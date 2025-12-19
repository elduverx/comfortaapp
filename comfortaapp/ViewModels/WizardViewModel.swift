import Foundation
import SwiftUI
import Combine

class WizardViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var lugarRecogida: String = ""
    @Published var destino: String = ""
    @Published var fechaInicio: Date = Date()
    @Published var franjaHoraria: String = "09:00-10:00"
    
    // Datos del pasajero
    @Published var nombrePasajero: String = ""
    @Published var telefonoPasajero: String = ""
    @Published var numeroPersonas: Int = 1
    @Published var equipajeAdicional: Bool = false
    @Published var notasEspeciales: String = ""
    
    // Estado de la reserva
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Navegación
    func goToNextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    func goToPreviousStep() {
        withAnimation {
            currentStep -= 1
        }
    }
    
    func resetWizard() {
        currentStep = 1
        lugarRecogida = ""
        destino = ""
        fechaInicio = Date()
        franjaHoraria = "09:00-10:00"
        nombrePasajero = ""
        telefonoPasajero = ""
        numeroPersonas = 1
        equipajeAdicional = false
        notasEspeciales = ""
        isLoading = false
        errorMessage = nil
    }
    
    // Validaciones
    var isStep1Valid: Bool {
        !lugarRecogida.isEmpty && !destino.isEmpty
    }
    
    var isStep2Valid: Bool {
        !nombrePasajero.isEmpty && !telefonoPasajero.isEmpty
    }
    
    // Datos del viaje para API
    var tripData: [String: Any] {
        return [
            "origen": lugarRecogida,
            "destino": destino,
            "fecha": fechaInicio.timeIntervalSince1970,
            "franjaHoraria": franjaHoraria,
            "nombrePasajero": nombrePasajero,
            "telefonoPasajero": telefonoPasajero,
            "numeroPersonas": numeroPersonas,
            "equipajeAdicional": equipajeAdicional,
            "notasEspeciales": notasEspeciales
        ]
    }
}