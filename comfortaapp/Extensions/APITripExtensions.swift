import Foundation
import SwiftUI

extension APITrip {
    private var normalizedEstado: String {
        estado.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var createdAtDate: Date? {
        createdAt.toDate()
    }

    var isCompleted: Bool {
        if normalizedEstado.contains("COMPLET") || normalizedEstado.contains("FINALIZ") {
            return true
        }
        return pagado
    }

    var isCancelled: Bool {
        normalizedEstado.contains("CANCEL") || normalizedEstado.contains("ANUL")
    }

    var isUpcoming: Bool {
        !isCompleted && !isCancelled
    }

    var statusDisplayName: String {
        switch normalizedEstado {
        case "PENDIENTE":
            return "Pendiente"
        case "CONFIRMADO":
            return "Confirmado"
        case "EN_PROCESO", "EN CURSO", "EN_CURSO":
            return "En curso"
        case "COMPLETADO", "FINALIZADO":
            return "Completado"
        case "CANCELADO", "ANULADO":
            return "Cancelado"
        default:
            return estado.capitalized.isEmpty ? "Pendiente" : estado.capitalized
        }
    }

    var statusColor: Color {
        if isCompleted {
            return ComfortaDesign.Colors.primaryGreen
        }
        if isCancelled {
            return ComfortaDesign.Colors.error
        }
        return ComfortaDesign.Colors.warning
    }

    var formattedPrice: String {
        let amount = precioTotal ?? precioBase ?? 0
        return APITrip.currencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "€%.2f", amount)
    }

    var formattedDistance: String {
        guard let distance = distanciaKm else {
            return "-"
        }
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        }
        return String(format: "%.1f km", distance)
    }

    var formattedDuration: String {
        if let duracion = duracion, !duracion.isEmpty {
            return duracion
        }
        guard let distance = distanciaKm else {
            return "-"
        }
        let minutes = max(1, Int(distance))
        return "\(minutes) min"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
}
