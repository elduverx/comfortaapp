import Foundation

struct AdminTripsResponse: Codable {
    let success: Bool
    let data: [AdminTripDTO]
}

struct AdminTripResponse: Codable {
    let success: Bool
    let trip: AdminTripDTO
}

struct AdminTripDTO: Codable, Identifiable {
    let id: String
    let shortId: String?
    let userId: String?
    let lugarRecogida: String?
    let destino: String
    let fechaInicio: Date
    let fechaFin: Date?
    let franjaHoraria: String?
    let nombreUsuario: String?
    let email: String?
    let telefono: String?
    let estado: String
    let distanciaKm: Double?
    let precioBase: Double?
    let recargoAeropuerto: Double?
    let precioTotal: Double?
    let pagado: Bool?
    let numeroFactura: String?
    let paymentMethod: String?
    let paymentOrderId: String?
    let paymentDate: Date?
    let notas: String?
    let notasAdmin: String?
    let conductorId: String?
    let conductorNombre: String?
    let createdAt: Date
    let updatedAt: Date?
}

struct AdminUsersResponse: Codable {
    let success: Bool
    let data: [AdminUserDTO]
}

struct AdminUserDTO: Codable, Identifiable {
    let id: String
    let name: String?
    let email: String?
    let telefono: String?
    let createdAt: Date
    let updatedAt: Date
    let totalTrips: Int
    let totalSpent: Double
}

// MARK: - Admin Actions

struct UpdateTripStatusRequest: Codable {
    let estado: String
    let notasAdmin: String?
}

struct AssignDriverRequest: Codable {
    let conductorId: String
    let conductorNombre: String
    let estado: String
}
