import Foundation
import SwiftUI

// MARK: - Audit Log Service

actor AuditLogService {
    static let shared = AuditLogService()

    private var changes: [ConfigurationChange] = []
    private let maxStoredChanges = 1000
    private let storageKey = "audit_log_changes"

    private init() {
        Task {
            await loadFromStorage()
        }
    }

    func log(_ change: ConfigurationChange) {
        changes.insert(change, at: 0)

        // Keep only the most recent changes
        if changes.count > maxStoredChanges {
            changes = Array(changes.prefix(maxStoredChanges))
        }

        Task {
            await saveToStorage()
        }

        print("📝 [Audit Log] \(change.section) - \(change.field): \(change.oldValue) → \(change.newValue)")
    }

    func getAllChanges() -> [ConfigurationChange] {
        return changes
    }

    func getChanges(section: String? = nil, limit: Int = 100) -> [ConfigurationChange] {
        var filtered = changes

        if let section = section {
            filtered = filtered.filter { $0.section == section }
        }

        return Array(filtered.prefix(limit))
    }

    func getChangesByDateRange(from startDate: Date, to endDate: Date) -> [ConfigurationChange] {
        return changes.filter { change in
            change.timestamp >= startDate && change.timestamp <= endDate
        }
    }

    func clearOldChanges(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        changes.removeAll { $0.timestamp < cutoffDate }

        Task {
            await saveToStorage()
        }
    }

    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(changes) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ConfigurationChange].self, from: data) {
            changes = decoded
        }
    }

    func exportAuditLog(format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return generateCSV()
        case .json:
            return try? JSONEncoder().encode(changes)
        case .pdf:
            return generatePDF()
        }
    }

    private func generateCSV() -> Data? {
        var csv = "Timestamp,Section,Field,Old Value,New Value,Admin\n"

        for change in changes {
            let timestamp = ISO8601DateFormatter().string(from: change.timestamp)
            csv += "\(timestamp),\(change.section),\(change.field),\(change.oldValue),\(change.newValue),\(change.adminName)\n"
        }

        return csv.data(using: .utf8)
    }

    private func generatePDF() -> Data? {
        // Simplified PDF generation
        var pdfContent = "AUDIT LOG REPORT\n\n"
        pdfContent += "Generated: \(Date())\n"
        pdfContent += "Total Changes: \(changes.count)\n\n"

        for change in changes.prefix(100) {
            pdfContent += "[\(change.timestamp)] \(change.section) - \(change.field)\n"
            pdfContent += "  \(change.oldValue) → \(change.newValue)\n"
            pdfContent += "  By: \(change.adminName)\n\n"
        }

        return pdfContent.data(using: .utf8)
    }
}

// MARK: - Configuration Change Model

struct ConfigurationChange: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let section: String
    let field: String
    let oldValue: String
    let newValue: String
    let adminName: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        section: String,
        field: String,
        oldValue: String,
        newValue: String,
        adminName: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.section = section
        self.field = field
        self.oldValue = oldValue
        self.newValue = newValue
        self.adminName = adminName
    }
}
