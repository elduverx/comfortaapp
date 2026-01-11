import Foundation
import Combine
import SwiftUI
import CoreLocation

class AdminService: ObservableObject {
    static let shared = AdminService()
    
    // MARK: - Published Properties
    @Published var stats = AdminStats()
    @Published var revenueData: [RevenueData] = []
    @Published var tripStatusData: [TripStatusData] = []
    @Published var paymentMethodData: [PaymentMethodData] = []
    @Published var recentActivities: [AdminActivity] = []
    @Published var recentTransactions: [PaymentRecord] = []
    @Published var systemStatus = SystemStatus()
    @Published var criticalAlerts: [AdminAlert] = []
    @Published var topDrivers: [DriverPerformance] = []
    @Published var supportTickets: [SupportTicket] = []
    
    // User Management
    @Published var allUsers: [User] = []
    @Published var userSearchQuery = ""
    @Published var selectedUserFilter: UserFilter = .all
    
    // Trip Management
    @Published var allTrips: [Trip] = []
    @Published var tripSearchQuery = ""
    @Published var selectedTripStatus: TripStatus?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Update filtered users when search query or filter changes
        Publishers.CombineLatest($userSearchQuery, $selectedUserFilter)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Update filtered trips when search query or status filter changes
        Publishers.CombineLatest($tripSearchQuery, $selectedTripStatus)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadDashboardData() {
        loadStats()
        loadRevenueData()
        loadTripStatusData()
        loadPaymentMethodData()
        loadRecentActivities()
        loadRecentTransactions()
        loadSystemStatus()
        loadAlerts()
        loadTopDrivers()
        loadSupportTickets()
        loadUsers()
        loadTrips()
    }
    
    private func loadStats() {
        // Simulate loading stats from server
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stats = AdminStats(
                totalActiveUsers: 1247,
                newUsersToday: 23,
                tripsToday: 156,
                tripGrowthPercent: 12.5,
                totalRevenue: 45670.0,
                revenueToday: 2340.0,
                monthlyRevenue: 134500.0,
                monthlyGrowth: 8.3,
                driversOnline: 89,
                driverUtilization: 87.2,
                platformCommission: 6725.0,
                commissionRate: 15.0
            )
        }
    }
    
    private func loadRevenueData() {
        // Generate last 7 days revenue data
        let calendar = Calendar.current
        var data: [RevenueData] = []
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let revenue = Double.random(in: 1500...3500)
            data.append(RevenueData(date: date, revenue: revenue))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.revenueData = data
        }
    }
    
    private func loadTripStatusData() {
        let data = [
            TripStatusData(status: "Completados", count: 234, color: Color.green),
            TripStatusData(status: "En Progreso", count: 45, color: Color.blue),
            TripStatusData(status: "Cancelados", count: 23, color: Color.red),
            TripStatusData(status: "Programados", count: 67, color: Color.orange)
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.tripStatusData = data
        }
    }
    
    private func loadPaymentMethodData() {
        let data = [
            PaymentMethodData(method: "Apple Pay", count: 156),
            PaymentMethodData(method: "Tarjeta", count: 89),
            PaymentMethodData(method: "Efectivo", count: 34)
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.paymentMethodData = data
        }
    }
    
    private func loadRecentActivities() {
        let activities = [
            AdminActivity(
                type: .userRegistered,
                description: "Nuevo usuario registrado: María García",
                timestamp: Date().addingTimeInterval(-300),
                icon: "person.badge.plus"
            ),
            AdminActivity(
                type: .tripCompleted,
                description: "Viaje completado: Madrid → Barcelona",
                timestamp: Date().addingTimeInterval(-600),
                icon: "checkmark.circle"
            ),
            AdminActivity(
                type: .driverVerified,
                description: "Conductor verificado: Carlos Ruiz",
                timestamp: Date().addingTimeInterval(-900),
                icon: "person.crop.circle.badge.checkmark"
            ),
            AdminActivity(
                type: .paymentProcessed,
                description: "Pago procesado: €67.50",
                timestamp: Date().addingTimeInterval(-1200),
                icon: "creditcard"
            ),
            AdminActivity(
                type: .userSuspended,
                description: "Usuario suspendido por violación de términos",
                timestamp: Date().addingTimeInterval(-1800),
                icon: "person.crop.circle.badge.xmark"
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.recentActivities = activities
        }
    }
    
    private func loadRecentTransactions() {
        let transactions = [
            PaymentRecord(
                tripId: "trip_001",
                userId: "user_001", 
                amount: 45.50,
                method: .applePay,
                transactionId: "txn_1234567890"
            ),
            PaymentRecord(
                tripId: "trip_002",
                userId: "user_002",
                amount: 67.80,
                method: .creditCard,
                transactionId: "txn_0987654321"
            ),
            PaymentRecord(
                tripId: "trip_003",
                userId: "user_003",
                amount: 23.20,
                method: .cash,
                transactionId: "txn_1122334455"
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.recentTransactions = transactions
        }
    }
    
    private func loadSystemStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.systemStatus = SystemStatus(
                uptimePercentage: 99.92,
                averageResponseTime: 180,
                incidentsToday: 1,
                paymentsOperational: true,
                mapsOperational: true,
                realtimeOperational: false,
                lastSync: Date()
            )
        }
    }
    
    private func loadAlerts() {
        let alerts = [
            AdminAlert(
                title: "Retraso en tracking en vivo",
                message: "El servicio de localización reporta latencia alta en Valencia.",
                severity: .critical,
                timestamp: Date().addingTimeInterval(-120),
                isResolved: false
            ),
            AdminAlert(
                title: "Conductores pendientes",
                message: "5 conductores esperan verificación de documentos.",
                severity: .warning,
                timestamp: Date().addingTimeInterval(-900),
                isResolved: false
            ),
            AdminAlert(
                title: "Nueva normativa",
                message: "Actualiza la política de protección de datos antes del viernes.",
                severity: .info,
                timestamp: Date().addingTimeInterval(-3600),
                isResolved: false
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.criticalAlerts = alerts
        }
    }
    
    private func loadTopDrivers() {
        let drivers = [
            DriverPerformance(name: "Carlos Ruiz", rating: 4.9, completedTrips: 128, earnings: 1940, status: .online),
            DriverPerformance(name: "Ana López", rating: 4.8, completedTrips: 115, earnings: 1820, status: .onTrip),
            DriverPerformance(name: "Miguel Torres", rating: 4.7, completedTrips: 103, earnings: 1765, status: .offline)
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            self.topDrivers = drivers
        }
    }
    
    private func loadSupportTickets() {
        let tickets = [
            SupportTicket(
                reference: "SUP-2391",
                userName: "Lucía P.",
                subject: "Reembolso parcial",
                priority: .high,
                status: .open,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            SupportTicket(
                reference: "SUP-2384",
                userName: "Daniel G.",
                subject: "Tarifa incorrecta",
                priority: .medium,
                status: .inProgress,
                createdAt: Date().addingTimeInterval(-14400)
            ),
            SupportTicket(
                reference: "SUP-2377",
                userName: "Beatriz M.",
                subject: "Problemas con Apple Pay",
                priority: .low,
                status: .resolved,
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            self.supportTickets = tickets
        }
    }
    
    private func loadUsers() {
        // Generate sample users
        let users = [
            User(id: "1", firstName: "María", lastName: "García", email: "maria@email.com"),
            User(id: "2", firstName: "Carlos", lastName: "Ruiz", email: "carlos@email.com"),
            User(id: "3", firstName: "Ana", lastName: "López", email: "ana@email.com"),
            User(id: "4", firstName: "Miguel", lastName: "Torres", email: "miguel@email.com"),
            User(id: "5", firstName: "Laura", lastName: "Martín", email: "laura@email.com")
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.allUsers = users
        }
    }
    
    private func loadTrips() {
        // Generate sample trips
        let trips = (1...10).map { i in
            Trip(
                userId: "user_\(i)",
                pickupLocation: LocationInfo(
                    address: "Dirección de recogida \(i)",
                    coordinate: CLLocationCoordinate2D(latitude: 40.4165, longitude: -3.7026)
                ),
                destinationLocation: LocationInfo(
                    address: "Destino \(i)",
                    coordinate: CLLocationCoordinate2D(latitude: 40.4839, longitude: -3.5680)
                ),
                estimatedFare: Double.random(in: 20...100),
                estimatedDistance: Double.random(in: 5...50),
                estimatedDuration: Double.random(in: 900...3600),
                vehicleType: VehicleType.allCases.randomElement()?.rawValue ?? "sedan",
                paymentMethod: PaymentMethodInfo(type: PaymentType.allCases.randomElement() ?? .applePay)
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.allTrips = trips
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredUsers: [User] {
        var users = allUsers
        
        // Apply search filter
        if !userSearchQuery.isEmpty {
            users = users.filter { user in
                user.fullName.localizedCaseInsensitiveContains(userSearchQuery) ||
                user.email?.localizedCaseInsensitiveContains(userSearchQuery) == true
            }
        }
        
        // Apply type filter
        switch selectedUserFilter {
        case .all:
            break
        case .passengers:
            users = users.filter { $0.userType == .passenger }
        case .drivers:
            users = users.filter { $0.userType == .driver }
        case .active:
            users = users.filter { $0.isActive }
        }
        
        return users
    }
    
    var filteredTrips: [Trip] {
        var trips = allTrips
        
        // Apply search filter
        if !tripSearchQuery.isEmpty {
            trips = trips.filter { trip in
                trip.id.localizedCaseInsensitiveContains(tripSearchQuery) ||
                trip.pickupLocation.address.localizedCaseInsensitiveContains(tripSearchQuery) ||
                trip.destinationLocation.address.localizedCaseInsensitiveContains(tripSearchQuery)
            }
        }
        
        // Apply status filter
        if let status = selectedTripStatus {
            trips = trips.filter { $0.status == status }
        }
        
        return trips.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - User Management
    
    func suspendUser(_ userId: String, reason: String) {
        if let index = allUsers.firstIndex(where: { $0.id == userId }) {
            allUsers[index].isActive = false
            
            let activity = AdminActivity(
                type: .userSuspended,
                description: "Usuario suspendido: \(allUsers[index].fullName)",
                timestamp: Date(),
                icon: "person.crop.circle.badge.xmark"
            )
            recentActivities.insert(activity, at: 0)
            
            AnalyticsService.shared.track(.userSuspended, metadata: [
                "user_id": userId,
                "reason": reason
            ])
        }
    }
    
    func reactivateUser(_ userId: String) {
        if let index = allUsers.firstIndex(where: { $0.id == userId }) {
            allUsers[index].isActive = true
            
            let activity = AdminActivity(
                type: .userReactivated,
                description: "Usuario reactivado: \(allUsers[index].fullName)",
                timestamp: Date(),
                icon: "person.crop.circle.badge.checkmark"
            )
            recentActivities.insert(activity, at: 0)
            
            AnalyticsService.shared.track(.userReactivated, metadata: [
                "user_id": userId
            ])
        }
    }
    
    // MARK: - Trip Management
    
    func cancelTrip(_ tripId: String, reason: String) {
        if let index = allTrips.firstIndex(where: { $0.id == tripId }) {
            allTrips[index].status = .cancelled
            allTrips[index].cancelledAt = Date()
            
            let activity = AdminActivity(
                type: .tripCancelled,
                description: "Viaje cancelado por administrador: #\(tripId.prefix(8))",
                timestamp: Date(),
                icon: "xmark.circle"
            )
            recentActivities.insert(activity, at: 0)
            
            AnalyticsService.shared.track(.tripCancelledByAdmin, metadata: [
                "trip_id": tripId,
                "reason": reason
            ])
        }
    }
    
    // MARK: - Financial Operations
    
    func processRefund(_ transactionId: String, amount: Double) {
        // In a real app, this would integrate with payment processor
        
        let activity = AdminActivity(
            type: .refundProcessed,
            description: String(format: "Reembolso procesado: €%.2f", amount),
            timestamp: Date(),
            icon: "arrow.uturn.left.circle"
        )
        recentActivities.insert(activity, at: 0)
        
        AnalyticsService.shared.track(.refundProcessed, metadata: [
            "transaction_id": transactionId,
            "amount": String(amount)
        ])
    }
    
    func updatePricingStructure(_ newPricing: PricingStructure) {
        // Update pricing in the system
        PricingService.shared.updatePricingStructure(newPricing)
        
        let activity = AdminActivity(
            type: .settingsChanged,
            description: "Estructura de precios actualizada",
            timestamp: Date(),
            icon: "eurosign.circle"
        )
        recentActivities.insert(activity, at: 0)
        
        AnalyticsService.shared.track(.pricingUpdated)
    }
    
    // MARK: - Alerts & Support
    
    func resolveAlert(_ alertId: UUID) {
        guard let index = criticalAlerts.firstIndex(where: { $0.id == alertId }) else { return }
        criticalAlerts[index].isResolved = true
        AnalyticsService.shared.track(.alertResolved, metadata: ["alert_id": alertId.uuidString])
    }
    
    func updateTicket(_ ticketId: UUID, status: TicketStatus) {
        guard let index = supportTickets.firstIndex(where: { $0.id == ticketId }) else { return }
        supportTickets[index].status = status
        if status == .resolved {
            AnalyticsService.shared.track(.supportTicketResolved, metadata: ["ticket_id": ticketId.uuidString])
        }
    }
    
    // MARK: - Analytics
    
    func generateReport(for period: ReportPeriod) -> AdminReport {
        // Generate comprehensive report
        return AdminReport(
            period: period,
            totalUsers: allUsers.count,
            activeUsers: allUsers.filter { $0.isActive }.count,
            totalTrips: allTrips.count,
            completedTrips: allTrips.filter { $0.status == .completed }.count,
            totalRevenue: allTrips.compactMap { $0.actualFare }.reduce(0, +),
            averageRating: allUsers.compactMap { $0.rating }.reduce(0, +) / Double(allUsers.count),
            generatedAt: Date()
        )
    }
    
    func exportData(format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return generateCSVData()
        case .json:
            return generateJSONData()
        case .pdf:
            return generatePDFData()
        }
    }
    
    private func generateCSVData() -> Data? {
        var csvContent = "Trip ID,User ID,Pickup,Destination,Fare,Status,Date\n"
        
        for trip in allTrips {
            csvContent += "\(trip.id),\(trip.userId),\(trip.pickupLocation.address),\(trip.destinationLocation.address),\(trip.estimatedFare),\(trip.status.rawValue),\(trip.createdAt)\n"
        }
        
        return csvContent.data(using: .utf8)
    }
    
    private func generateJSONData() -> Data? {
        let reportData = [
            "stats": stats,
            "users": allUsers,
            "trips": allTrips,
            "generated_at": Date()
        ] as [String: Any]
        
        return try? JSONSerialization.data(withJSONObject: reportData)
    }
    
    private func generatePDFData() -> Data? {
        // In a real app, this would generate a proper PDF
        return "PDF Report Data".data(using: .utf8)
    }
}

// MARK: - Supporting Types

struct AdminStats {
    var totalActiveUsers: Int = 0
    var newUsersToday: Int = 0
    var tripsToday: Int = 0
    var tripGrowthPercent: Double = 0.0
    var totalRevenue: Double = 0.0
    var revenueToday: Double = 0.0
    var monthlyRevenue: Double = 0.0
    var monthlyGrowth: Double = 0.0
    var driversOnline: Int = 0
    var driverUtilization: Double = 0.0
    var platformCommission: Double = 0.0
    var commissionRate: Double = 0.0
}

struct RevenueData: Identifiable {
    let id = UUID()
    let date: Date
    let revenue: Double
}

struct TripStatusData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

struct PaymentMethodData: Identifiable {
    let id = UUID()
    let method: String
    let count: Int
}

struct SystemStatus {
    var uptimePercentage: Double = 0
    var averageResponseTime: Double = 0
    var incidentsToday: Int = 0
    var paymentsOperational: Bool = true
    var mapsOperational: Bool = true
    var realtimeOperational: Bool = true
    var lastSync: Date = Date()
}

struct AdminAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    var isResolved: Bool
}

enum AlertSeverity {
    case info
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .info: return ComfortaDesign.Colors.info
        case .warning: return ComfortaDesign.Colors.warning
        case .critical: return ComfortaDesign.Colors.error
        }
    }
}

struct DriverPerformance: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
    let completedTrips: Int
    let earnings: Double
    let status: DriverStatus
}

enum DriverStatus {
    case online
    case onTrip
    case offline
    
    var label: String {
        switch self {
        case .online: return "Disponible"
        case .onTrip: return "En viaje"
        case .offline: return "Descansando"
        }
    }
    
    var color: Color {
        switch self {
        case .online: return ComfortaDesign.Colors.primaryGreen
        case .onTrip: return ComfortaDesign.Colors.warning
        case .offline: return ComfortaDesign.Colors.textSecondary
        }
    }
}

struct SupportTicket: Identifiable {
    let id = UUID()
    let reference: String
    let userName: String
    let subject: String
    let priority: TicketPriority
    var status: TicketStatus
    let createdAt: Date
}

enum TicketPriority {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low: return ComfortaDesign.Colors.info
        case .medium: return ComfortaDesign.Colors.warning
        case .high: return ComfortaDesign.Colors.error
        }
    }
    
    var title: String {
        switch self {
        case .low: return "Baja"
        case .medium: return "Media"
        case .high: return "Alta"
        }
    }
}

enum TicketStatus: CaseIterable {
    case open
    case inProgress
    case resolved
    
    var title: String {
        switch self {
        case .open: return "Abierto"
        case .inProgress: return "En curso"
        case .resolved: return "Resuelto"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return ComfortaDesign.Colors.warning
        case .inProgress: return ComfortaDesign.Colors.info
        case .resolved: return ComfortaDesign.Colors.primaryGreen
        }
    }
}

struct AdminActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let timestamp: Date
    let icon: String
}

enum ActivityType {
    case userRegistered
    case userSuspended
    case userReactivated
    case tripCompleted
    case tripCancelled
    case driverVerified
    case paymentProcessed
    case refundProcessed
    case settingsChanged
}

enum UserFilter {
    case all
    case passengers
    case drivers
    case active
}

enum ReportPeriod {
    case daily
    case weekly
    case monthly
    case yearly
}

enum ExportFormat {
    case csv
    case json
    case pdf
}

struct AdminReport {
    let period: ReportPeriod
    let totalUsers: Int
    let activeUsers: Int
    let totalTrips: Int
    let completedTrips: Int
    let totalRevenue: Double
    let averageRating: Double
    let generatedAt: Date
}

struct PricingStructure: Codable {
    var baseFare: Double
    var perKilometerRate: Double
    var perMinuteRate: Double
    var minimumFare: Double
    var commissionRate: Double
    var vehicleMultipliers: [String: Double]
    
    init(baseFare: Double = 3.50, perKilometerRate: Double = 1.20, perMinuteRate: Double = 0.35, minimumFare: Double = 5.00, commissionRate: Double = 15.0, vehicleMultipliers: [String: Double] = ["sedan": 1.0, "suv": 1.2, "van": 1.5, "luxury": 2.0]) {
        self.baseFare = baseFare
        self.perKilometerRate = perKilometerRate
        self.perMinuteRate = perMinuteRate
        self.minimumFare = minimumFare
        self.commissionRate = commissionRate
        self.vehicleMultipliers = vehicleMultipliers
    }
}
