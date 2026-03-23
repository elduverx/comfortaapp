import SwiftUI
import Foundation
import Combine

// MARK: - Pricing ViewModel

class AdminPricingViewModel: ObservableObject {
    @Published var pricing: PricingStructure
    @Published var hasChanges = false
    @Published var isSaving = false
    @Published var error: Error?
    @Published var validationErrors: [String: String] = [:]
    @Published var showingComparison = false

    private var originalPricing: PricingStructure
    private var cancellables = Set<AnyCancellable>()

    init(pricing: PricingStructure) {
        self.pricing = pricing
        self.originalPricing = pricing
        setupObservers()
    }

    private func setupObservers() {
        $pricing
            .sink { [weak self] newPricing in
                guard let self = self else { return }
                self.hasChanges = !self.arePricingsEqual(newPricing, self.originalPricing)
                self.validateAll()
            }
            .store(in: &cancellables)
    }

    func validateAll() {
        validationErrors.removeAll()

        // Validate base fare
        if pricing.baseFare < 0 {
            validationErrors["baseFare"] = "La tarifa base no puede ser negativa"
        } else if pricing.baseFare > 50 {
            validationErrors["baseFare"] = "La tarifa base parece muy alta (máx: €50)"
        }

        // Validate per kilometer rate
        if pricing.perKilometerRate < 0 {
            validationErrors["perKilometerRate"] = "La tarifa por km no puede ser negativa"
        } else if pricing.perKilometerRate > 10 {
            validationErrors["perKilometerRate"] = "La tarifa por km parece muy alta (máx: €10/km)"
        }

        // Validate minimum fares
        if pricing.minimumFare < 0 {
            validationErrors["minimumFare"] = "La tarifa mínima no puede ser negativa"
        }

        if pricing.minimumFareForLongTrips < pricing.minimumFare {
            validationErrors["minimumFareForLongTrips"] = "Debe ser mayor o igual a la tarifa mínima general"
        }

        // Validate threshold
        if pricing.minimumFareThreshold < 0 {
            validationErrors["minimumFareThreshold"] = "El umbral no puede ser negativo"
        } else if pricing.minimumFareThreshold < 5 {
            validationErrors["minimumFareThreshold"] = "El umbral parece muy bajo (mín: 5km)"
        }

        // Validate airport surcharge
        if pricing.airportSurcharge < 0 {
            validationErrors["airportSurcharge"] = "El recargo no puede ser negativo"
        } else if pricing.airportSurcharge > 50 {
            validationErrors["airportSurcharge"] = "El recargo parece muy alto (máx: €50)"
        }

        // Validate commission rate
        if pricing.commissionRate < 0 || pricing.commissionRate > 100 {
            validationErrors["commissionRate"] = "La comisión debe estar entre 0% y 100%"
        }

        // Validate vehicle multipliers
        for (vehicle, multiplier) in pricing.vehicleMultipliers {
            if multiplier < 0.5 || multiplier > 5.0 {
                validationErrors["multiplier_\(vehicle)"] = "El multiplicador debe estar entre 0.5x y 5.0x"
            }
        }
    }

    var isValid: Bool {
        validationErrors.isEmpty
    }

    func calculateImpact() -> PricingImpact? {
        let avgDistance = 10.0 // km
        let oldPrice = originalPricing.baseFare + (avgDistance * originalPricing.perKilometerRate)
        let newPrice = pricing.baseFare + (avgDistance * pricing.perKilometerRate)
        let difference = newPrice - oldPrice
        let percentChange = oldPrice > 0 ? (difference / oldPrice) * 100 : 0

        return PricingImpact(
            oldPrice: oldPrice,
            newPrice: newPrice,
            difference: difference,
            percentChange: percentChange
        )
    }

    func save() async -> Bool {
        guard isValid else { return false }

        await MainActor.run {
            isSaving = true
            error = nil
        }

        do {
            // Log the change
            await logConfigurationChange()

            // Save to service
            await MainActor.run {
                AdminService.shared.updatePricingStructure(pricing)
                PricingService.shared.updatePricingStructure(pricing)
                originalPricing = pricing
                hasChanges = false
                isSaving = false
            }

            return true
        } catch let saveError {
            await MainActor.run {
                error = saveError
                isSaving = false
            }
            return false
        }
    }

    func reset() {
        pricing = originalPricing
        hasChanges = false
        validationErrors.removeAll()
    }

    private func logConfigurationChange() async {
        let changes = compareChanges()
        for change in changes {
            await AuditLogService.shared.log(change)
        }
    }

    private func compareChanges() -> [ConfigurationChange] {
        var changes: [ConfigurationChange] = []

        if originalPricing.baseFare != pricing.baseFare {
            changes.append(ConfigurationChange(
                section: "Precios",
                field: "Tarifa Base",
                oldValue: "€\(String(format: "%.2f", originalPricing.baseFare))",
                newValue: "€\(String(format: "%.2f", pricing.baseFare))",
                adminName: "Admin"
            ))
        }

        if originalPricing.perKilometerRate != pricing.perKilometerRate {
            changes.append(ConfigurationChange(
                section: "Precios",
                field: "Por Kilómetro",
                oldValue: "€\(String(format: "%.2f", originalPricing.perKilometerRate))/km",
                newValue: "€\(String(format: "%.2f", pricing.perKilometerRate))/km",
                adminName: "Admin"
            ))
        }

        if originalPricing.minimumFare != pricing.minimumFare {
            changes.append(ConfigurationChange(
                section: "Precios",
                field: "Tarifa Mínima",
                oldValue: "€\(String(format: "%.2f", originalPricing.minimumFare))",
                newValue: "€\(String(format: "%.2f", pricing.minimumFare))",
                adminName: "Admin"
            ))
        }

        return changes
    }

    private func arePricingsEqual(_ p1: PricingStructure, _ p2: PricingStructure) -> Bool {
        return p1.baseFare == p2.baseFare &&
               p1.perKilometerRate == p2.perKilometerRate &&
               p1.perMinuteRate == p2.perMinuteRate &&
               p1.minimumFare == p2.minimumFare &&
               p1.minimumFareForLongTrips == p2.minimumFareForLongTrips &&
               p1.minimumFareThreshold == p2.minimumFareThreshold &&
               p1.airportSurcharge == p2.airportSurcharge &&
               p1.commissionRate == p2.commissionRate
    }
}

// MARK: - Suspended Users ViewModel

class SuspendedUsersViewModel: ObservableObject {
    @Published var suspendedUsers: [SuspendedUser] = []
    @Published var searchText = ""
    @Published var sortOption: SortOption = .date
    @Published var filterOption: FilterOption = .all
    @Published var isLoading = false

    enum SortOption: String, CaseIterable {
        case date = "Fecha"
        case name = "Nombre"
        case totalSpent = "Gasto Total"
        case reason = "Razón"
    }

    enum FilterOption: String, CaseIterable {
        case all = "Todos"
        case highSpenders = "Alto Gasto (>€500)"
        case recent = "Recientes (< 7 días)"
        case longTerm = "Largo Plazo (> 30 días)"
    }

    var filteredUsers: [SuspendedUser] {
        var users = suspendedUsers

        // Apply search filter
        if !searchText.isEmpty {
            users = users.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText) ||
                user.reason.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply category filter
        switch filterOption {
        case .all:
            break
        case .highSpenders:
            users = users.filter { $0.totalSpent > 500 }
        case .recent:
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            users = users.filter { $0.suspendedDate > sevenDaysAgo }
        case .longTerm:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            users = users.filter { $0.suspendedDate < thirtyDaysAgo }
        }

        // Apply sorting
        return users.sorted { user1, user2 in
            switch sortOption {
            case .date:
                return user1.suspendedDate > user2.suspendedDate
            case .name:
                return user1.name < user2.name
            case .totalSpent:
                return user1.totalSpent > user2.totalSpent
            case .reason:
                return user1.reason < user2.reason
            }
        }
    }

    func loadUsers() async {
        await MainActor.run {
            isLoading = true
        }

        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            suspendedUsers = AdminService.shared.allUsers
                .filter { !$0.isActive }
                .map { user in
                    SuspendedUser(
                        id: user.id,
                        name: user.fullName,
                        email: user.email ?? "",
                        suspendedDate: Date().addingTimeInterval(-86400 * Double.random(in: 1...60)),
                        reason: ["Violación de términos", "Comportamiento inapropiado", "Fraude detectado", "Múltiples cancelaciones"].randomElement() ?? "Otros",
                        totalTrips: user.totalTrips,
                        totalSpent: user.totalSpent
                    )
                }
            isLoading = false
        }
    }

    func reactivateUser(_ userId: String) async {
        await MainActor.run {
            AdminService.shared.reactivateUser(userId)
            suspendedUsers.removeAll { $0.id == userId }
        }

        await AuditLogService.shared.log(ConfigurationChange(
            section: "Usuarios",
            field: "Reactivación",
            oldValue: "Suspendido",
            newValue: "Activo",
            adminName: "Admin"
        ))
    }

    func permanentBan(_ userId: String) async {
        await MainActor.run {
            // Mark as permanently banned
            suspendedUsers.removeAll { $0.id == userId }
        }

        await AuditLogService.shared.log(ConfigurationChange(
            section: "Usuarios",
            field: "Baneo Permanente",
            oldValue: "Suspendido",
            newValue: "Baneado Permanentemente",
            adminName: "Admin"
        ))
    }
}

// MARK: - Export ViewModel

class ExportViewModel: ObservableObject {
    @Published var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var endDate = Date()
    @Published var includeUserData = true
    @Published var includeTrips = true
    @Published var includeFinancials = true
    @Published var selectedFormat: ExportFormat = .pdf
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportError: String?

    func exportWithOptions() async -> Bool {
        await MainActor.run {
            isExporting = true
            exportProgress = 0.0
            exportError = nil
        }

        do {
            // Simulate export with progress
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    exportProgress = Double(i) / 10.0
                }
            }

            let options = ExportOptions(
                startDate: startDate,
                endDate: endDate,
                includeUsers: includeUserData,
                includeTrips: includeTrips,
                includeFinancials: includeFinancials
            )

            guard let data = AdminService.shared.exportData(format: selectedFormat, options: options) else {
                throw ExportError.dataGenerationFailed
            }

            // Save file
            try saveExportedData(data)

            await MainActor.run {
                isExporting = false
                exportProgress = 1.0
            }

            await AuditLogService.shared.log(ConfigurationChange(
                section: "Reportes",
                field: "Exportación",
                oldValue: "",
                newValue: "Formato: \(selectedFormat.rawValue), Período: \(formatDateRange())",
                adminName: "Admin"
            ))

            return true

        } catch {
            await MainActor.run {
                exportError = error.localizedDescription
                isExporting = false
            }
            return false
        }
    }

    private func saveExportedData(_ data: Data) throws {
        let fileName = "comforta_export_\(Date().timeIntervalSince1970).\(selectedFormat.rawValue)"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(fileName)
        try data.write(to: fileURL)
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var isValid: Bool {
        startDate <= endDate
    }
}

// MARK: - Supporting Types

struct PricingImpact {
    let oldPrice: Double
    let newPrice: Double
    let difference: Double
    let percentChange: Double

    var isIncrease: Bool {
        difference > 0
    }

    var impactDescription: String {
        let sign = isIncrease ? "+" : ""
        return "\(sign)€\(String(format: "%.2f")) (\(sign)\(String(format: "%.1f", percentChange))%)"
    }

    var impactColor: Color {
        if abs(percentChange) < 5 {
            return ComfortaDesign.Colors.info
        } else if isIncrease {
            return ComfortaDesign.Colors.warning
        } else {
            return ComfortaDesign.Colors.primaryGreen
        }
    }
}

struct ExportOptions {
    let startDate: Date
    let endDate: Date
    let includeUsers: Bool
    let includeTrips: Bool
    let includeFinancials: Bool
}

enum ExportError: LocalizedError {
    case dataGenerationFailed
    case fileSaveFailed

    var errorDescription: String? {
        switch self {
        case .dataGenerationFailed:
            return "No se pudo generar los datos de exportación"
        case .fileSaveFailed:
            return "No se pudo guardar el archivo"
        }
    }
}
