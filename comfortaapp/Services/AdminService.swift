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
    @Published var isAutoRefreshEnabled = false
    @Published var newTripsCount = 0

    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let commissionRate: Double = 0.15
    private var adminTripSnapshots: [AdminTripDTO] = []
    private var adminUserSnapshots: [AdminUserDTO] = []
    private var autoRefreshTask: Task<Void, Never>?
    private var previousTripIds = Set<String>()
    private let adminTripsStorageKey = "admin_trip_snapshots_v1"
    private let adminUsersStorageKey = "admin_user_snapshots_v1"
    
    private init() {
        setupBindings()
        restoreAdminCache()
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
        loadSystemStatus()
        loadAlerts()
        loadTopDrivers()
        loadSupportTickets()
        Task {
            await refreshAdminData()
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        guard !isAutoRefreshEnabled else { return }

        isAutoRefreshEnabled = true
        print("🔄 Auto-refresh enabled for admin panel")

        autoRefreshTask = Task {
            while !Task.isCancelled && isAutoRefreshEnabled {
                // Refresh every 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)

                await refreshAdminData()
            }
        }
    }

    func stopAutoRefresh() {
        isAutoRefreshEnabled = false
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
        print("⏸️ Auto-refresh disabled")
    }

    private func refreshAdminData() async {
        if Task.isCancelled {
            return
        }

        var users = adminUserSnapshots
        var trips = adminTripSnapshots

        do {
            let usersResult: AdminUsersResponse = try await apiClient.request(
                endpoint: .adminUsers,
                method: .get,
                requiresAuth: false
            )

            if usersResult.success {
                users = usersResult.data
            } else {
                print("❌ Admin users response returned success=false")
            }
        } catch {
            if isCancellationError(error) {
                return
            }
            print("❌ Admin users sync failed: \(error)")
        }

        do {
            let tripsResult: AdminTripsResponse = try await apiClient.request(
                endpoint: .adminTrips,
                method: .get,
                requiresAuth: false
            )

            if tripsResult.success {
                trips = tripsResult.data
            } else {
                print("❌ Admin trips response returned success=false")
            }
        } catch {
            if isCancellationError(error) {
                return
            }
            print("❌ Admin trips sync failed: \(error)")
        }

        await MainActor.run {
            if Task.isCancelled {
                return
            }
            self.adminUserSnapshots = users
            self.adminTripSnapshots = trips

            // Detect new trips
            let currentTripIds = Set(trips.map { $0.id })
            let newTripIds = currentTripIds.subtracting(previousTripIds)

            self.allUsers = users.map { mapAdminUser($0) }
            self.allTrips = trips.map { mapAdminTrip($0) }
            self.refreshDerivedData()

            // Notify about new trips
            if !newTripIds.isEmpty && !previousTripIds.isEmpty {
                newTripsCount = newTripIds.count
                print("🔔 \(newTripIds.count) nuevo(s) viaje(s) detectado(s)")

                // Send local notification for each new trip
                for tripId in newTripIds {
                    if let trip = trips.first(where: { $0.id == tripId }) {
                        sendNewTripNotification(trip)
                    }
                }
            }

            previousTripIds = currentTripIds
            persistAdminCache()
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    private func refreshDerivedData() {
        let calendar = Calendar.current
        let now = Date()
        let trips = adminTripSnapshots
        let users = adminUserSnapshots

        let totalRevenue = trips.reduce(0) { $0 + ($1.precioTotal ?? 0) }
        let revenueToday = trips
            .filter { calendar.isDate(revenueDate(for: $0), inSameDayAs: now) }
            .reduce(0) { $0 + ($1.precioTotal ?? 0) }

        let tripsToday = trips.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }.count
        let tripsYesterday = trips.filter {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                return calendar.isDate($0.createdAt, inSameDayAs: yesterday)
            }
            return false
        }.count

        let tripGrowthPercent = tripsYesterday == 0
            ? 0
            : (Double(tripsToday - tripsYesterday) / Double(tripsYesterday)) * 100

        let currentMonthRevenue = revenueInMonth(referenceDate: now, trips: trips)
        let previousMonthRevenue = revenueInMonth(
            referenceDate: calendar.date(byAdding: .month, value: -1, to: now) ?? now,
            trips: trips
        )
        let monthlyGrowth = previousMonthRevenue == 0
            ? 0
            : ((currentMonthRevenue - previousMonthRevenue) / previousMonthRevenue) * 100

        stats = AdminStats(
            totalActiveUsers: allUsers.count,
            newUsersToday: users.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }.count,
            tripsToday: tripsToday,
            tripGrowthPercent: tripGrowthPercent,
            totalRevenue: totalRevenue,
            revenueToday: revenueToday,
            monthlyRevenue: currentMonthRevenue,
            monthlyGrowth: monthlyGrowth,
            driversOnline: 0,
            driverUtilization: 0,
            platformCommission: totalRevenue * commissionRate,
            commissionRate: commissionRate * 100
        )

        revenueData = buildRevenueData(referenceDate: now, trips: trips)
        tripStatusData = buildTripStatusData(trips: trips)
        paymentMethodData = buildPaymentMethodData(trips: trips)
        recentTransactions = buildRecentTransactions(trips: trips)
        recentActivities = buildRecentActivities(trips: trips, users: users)
        systemStatus.lastSync = now
    }

    private func mapAdminUser(_ user: AdminUserDTO) -> User {
        let name = splitName(user.name)
        var mapped = User(id: user.id, firstName: name.firstName, lastName: name.lastName, email: user.email)
        mapped.phoneNumber = user.telefono
        mapped.dateCreated = user.createdAt
        mapped.lastLoginDate = user.updatedAt
        mapped.memberSince = user.createdAt
        mapped.totalTrips = user.totalTrips
        mapped.totalSpent = user.totalSpent
        mapped.loyaltyPoints = Int(user.totalSpent * 10)
        mapped.userType = .passenger
        mapped.isActive = true
        mapped.rating = 5.0
        return mapped
    }

    private func mapAdminTrip(_ trip: AdminTripDTO) -> Trip {
        let pickupAddress = trip.lugarRecogida ?? "Recogida no especificada"
        let placeholderCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let pickup = LocationInfo(address: pickupAddress, coordinate: placeholderCoordinate)
        let destination = LocationInfo(address: trip.destino, coordinate: placeholderCoordinate)
        let paymentType = paymentType(from: trip.paymentMethod)
        let payment = PaymentMethodInfo(type: paymentType)

        return Trip(
            id: trip.id,
            userId: trip.userId ?? trip.email ?? trip.id,
            status: tripStatus(from: trip.estado),
            pickupLocation: pickup,
            destinationLocation: destination,
            estimatedFare: trip.precioTotal ?? 0,
            estimatedDistance: trip.distanciaKm ?? 0,
            estimatedDuration: 0,
            vehicleType: "sedan",
            paymentMethod: payment,
            createdAt: trip.createdAt,
            scheduledAt: trip.fechaInicio
        )
    }

    private func splitName(_ name: String?) -> (firstName: String, lastName: String) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let components = trimmed.split(separator: " ").map(String.init)

        guard let first = components.first else {
            return ("Usuario", "Comforta")
        }

        let last = components.dropFirst().joined(separator: " ")
        return (first, last.isEmpty ? "" : last)
    }

    private func tripStatus(from estado: String) -> TripStatus {
        switch estado.uppercased() {
        case "ACEPTADO":
            return .driverAssigned
        case "COMPLETADO":
            return .completed
        case "CANCELADO":
            return .cancelled
        case "RECHAZADO", "EXPIRADO":
            return .failed
        case "PENDIENTE":
            return .requested
        default:
            return .requested
        }
    }

    private func paymentType(from method: String?) -> PaymentType {
        switch method?.uppercased() {
        case "APPLE_PAY":
            return .applePay
        case "CASH", "EFECTIVO":
            return .cash
        default:
            return .creditCard
        }
    }

    private func revenueDate(for trip: AdminTripDTO) -> Date {
        trip.paymentDate ?? trip.createdAt
    }

    private func revenueInMonth(referenceDate: Date, trips: [AdminTripDTO]) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: referenceDate)

        return trips.filter {
            let tripComponents = calendar.dateComponents([.year, .month], from: revenueDate(for: $0))
            return tripComponents == components
        }.reduce(0) { $0 + ($1.precioTotal ?? 0) }
    }

    private func buildRevenueData(referenceDate: Date, trips: [AdminTripDTO]) -> [RevenueData] {
        let calendar = Calendar.current
        let days = (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: referenceDate)
        }

        return days.map { day in
            let revenue = trips
                .filter { calendar.isDate(revenueDate(for: $0), inSameDayAs: day) }
                .reduce(0) { $0 + ($1.precioTotal ?? 0) }
            return RevenueData(date: day, revenue: revenue)
        }
    }

    private func buildTripStatusData(trips: [AdminTripDTO]) -> [TripStatusData] {
        var completed = 0
        var inProgress = 0
        var cancelled = 0
        var scheduled = 0

        for trip in trips {
            switch trip.estado.uppercased() {
            case "COMPLETADO":
                completed += 1
            case "ACEPTADO":
                inProgress += 1
            case "PENDIENTE":
                scheduled += 1
            case "RECHAZADO", "CANCELADO", "EXPIRADO":
                cancelled += 1
            default:
                inProgress += 1
            }
        }

        return [
            TripStatusData(status: "Completados", count: completed, color: ComfortaDesign.Colors.primaryGreen),
            TripStatusData(status: "En Progreso", count: inProgress, color: ComfortaDesign.Colors.info),
            TripStatusData(status: "Cancelados", count: cancelled, color: ComfortaDesign.Colors.error),
            TripStatusData(status: "Programados", count: scheduled, color: ComfortaDesign.Colors.warning)
        ]
    }

    private func buildPaymentMethodData(trips: [AdminTripDTO]) -> [PaymentMethodData] {
        var counts: [PaymentType: Int] = [:]

        for trip in trips {
            let type = paymentType(from: trip.paymentMethod)
            counts[type, default: 0] += 1
        }

        let order: [PaymentType] = [.applePay, .creditCard, .cash]
        return order.map { type in
            PaymentMethodData(method: type.displayName, count: counts[type, default: 0])
        }
    }

    private func buildRecentTransactions(trips: [AdminTripDTO]) -> [PaymentRecord] {
        let sortedTrips = trips.sorted { revenueDate(for: $0) > revenueDate(for: $1) }

        return sortedTrips.compactMap { trip in
            guard let amount = trip.precioTotal else { return nil }
            let type = paymentType(from: trip.paymentMethod)
            let transactionId = trip.paymentOrderId ?? trip.shortId ?? trip.id

            return PaymentRecord(
                tripId: trip.id,
                userId: trip.userId ?? "unknown",
                amount: amount,
                method: type,
                transactionId: transactionId
            )
        }
        .prefix(6)
        .map { $0 }
    }

    private func buildRecentActivities(trips: [AdminTripDTO], users: [AdminUserDTO]) -> [AdminActivity] {
        let recentUsers = users.sorted { $0.createdAt > $1.createdAt }.prefix(5)
        let recentTrips = trips.sorted { revenueDate(for: $0) > revenueDate(for: $1) }.prefix(5)

        var activities: [AdminActivity] = []

        for user in recentUsers {
            let label = user.name ?? user.email ?? "Usuario"
            activities.append(
                AdminActivity(
                    type: .userRegistered,
                    description: "Nuevo usuario registrado: \(label)",
                    timestamp: user.createdAt,
                    icon: "person.badge.plus"
                )
            )
        }

        for trip in recentTrips {
            let tripLabel = trip.shortId ?? String(trip.id.prefix(8))
            let description: String
            let type: ActivityType
            let icon: String

            switch trip.estado.uppercased() {
            case "COMPLETADO":
                type = .tripCompleted
                icon = "checkmark.circle"
                description = "Viaje completado: #\(tripLabel)"
            case "RECHAZADO", "CANCELADO", "EXPIRADO":
                type = .tripCancelled
                icon = "xmark.circle"
                description = "Viaje cancelado: #\(tripLabel)"
            default:
                type = .paymentProcessed
                icon = "creditcard"
                description = "Pago procesado: #\(tripLabel)"
            }

            activities.append(
                AdminActivity(
                    type: type,
                    description: description,
                    timestamp: revenueDate(for: trip),
                    icon: icon
                )
            )
        }

        return activities.sorted { $0.timestamp > $1.timestamp }.prefix(8).map { $0 }
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

    func acceptTrip(_ tripId: String) async {
        do {
            let request = UpdateTripStatusRequest(estado: "ACEPTADO", notasAdmin: "Viaje aceptado por administrador")
            let _: MessageResponse = try await apiClient.request(
                endpoint: .adminTripDetail(id: tripId),
                method: .patch,
                body: request,
                requiresAuth: false
            )

            await MainActor.run {
                if let index = allTrips.firstIndex(where: { $0.id == tripId }) {
                    allTrips[index].status = .driverAssigned
                }

                let activity = AdminActivity(
                    type: .tripCompleted,
                    description: "Viaje aceptado: #\(tripId.prefix(8))",
                    timestamp: Date(),
                    icon: "checkmark.circle"
                )
                recentActivities.insert(activity, at: 0)

                AnalyticsService.shared.track(.tripAcceptedByAdmin, metadata: [
                    "trip_id": tripId
                ])
            }

            // Refresh data
            await refreshAdminData()
        } catch {
            print("❌ Error accepting trip: \(error)")
        }
    }

    func rejectTrip(_ tripId: String, reason: String) async {
        do {
            let request = UpdateTripStatusRequest(estado: "RECHAZADO", notasAdmin: reason)
            let _: MessageResponse = try await apiClient.request(
                endpoint: .adminTripDetail(id: tripId),
                method: .patch,
                body: request,
                requiresAuth: false
            )

            await MainActor.run {
                if let index = allTrips.firstIndex(where: { $0.id == tripId }) {
                    allTrips[index].status = .failed
                }

                let activity = AdminActivity(
                    type: .tripCancelled,
                    description: "Viaje rechazado: #\(tripId.prefix(8))",
                    timestamp: Date(),
                    icon: "xmark.circle"
                )
                recentActivities.insert(activity, at: 0)

                AnalyticsService.shared.track(.tripRejectedByAdmin, metadata: [
                    "trip_id": tripId,
                    "reason": reason
                ])
            }

            // Refresh data
            await refreshAdminData()
        } catch {
            print("❌ Error rejecting trip: \(error)")
        }
    }

    func assignDriver(_ tripId: String, driverId: String, driverName: String) async {
        do {
            let request = AssignDriverRequest(conductorId: driverId, conductorNombre: driverName, estado: "ACEPTADO")
            let _: MessageResponse = try await apiClient.request(
                endpoint: .adminTripDetail(id: tripId),
                method: .patch,
                body: request,
                requiresAuth: false
            )

            await MainActor.run {
                if let index = allTrips.firstIndex(where: { $0.id == tripId }) {
                    allTrips[index].status = .driverAssigned
                    allTrips[index].driverId = driverId
                }

                let activity = AdminActivity(
                    type: .tripCompleted,
                    description: "Conductor asignado a viaje #\(tripId.prefix(8)): \(driverName)",
                    timestamp: Date(),
                    icon: "person.circle.fill"
                )
                recentActivities.insert(activity, at: 0)

                AnalyticsService.shared.track(.driverAssignedByAdmin, metadata: [
                    "trip_id": tripId,
                    "driver_id": driverId
                ])
            }

            // Refresh data
            await refreshAdminData()
        } catch {
            print("❌ Error assigning driver: \(error)")
        }
    }

    func cancelTrip(_ tripId: String, reason: String) async {
        do {
            let request = UpdateTripStatusRequest(estado: "CANCELADO", notasAdmin: reason)
            let _: MessageResponse = try await apiClient.request(
                endpoint: .adminTripDetail(id: tripId),
                method: .patch,
                body: request,
                requiresAuth: false
            )

            await MainActor.run {
                if let index = allTrips.firstIndex(where: { $0.id == tripId }) {
                    allTrips[index].status = .cancelled
                    allTrips[index].cancelledAt = Date()
                }

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

            // Refresh data
            await refreshAdminData()
        } catch {
            print("❌ Error cancelling trip: \(error)")
        }
    }

    func completeTrip(_ tripId: String) async {
        do {
            let request = UpdateTripStatusRequest(estado: "COMPLETADO", notasAdmin: "Viaje completado por administrador")
            let _: MessageResponse = try await apiClient.request(
                endpoint: .adminTripDetail(id: tripId),
                method: .patch,
                body: request,
                requiresAuth: false
            )

            var completedTrip: Trip?

            await MainActor.run {
                if let index = allTrips.firstIndex(where: { $0.id == tripId }) {
                    allTrips[index].status = .completed
                    allTrips[index].droppedOffAt = Date()
                    completedTrip = allTrips[index]
                }

                let activity = AdminActivity(
                    type: .tripCompleted,
                    description: "Viaje completado: #\(tripId.prefix(8))",
                    timestamp: Date(),
                    icon: "checkmark.circle.fill"
                )
                recentActivities.insert(activity, at: 0)

                AnalyticsService.shared.track(.tripCompletedByAdmin, metadata: [
                    "trip_id": tripId
                ])
            }

            notifyUserTripCompleted(tripId: tripId, trip: completedTrip)

            // Refresh data
            await refreshAdminData()
        } catch {
            print("❌ Error completing trip: \(error)")
        }
    }

    private func notifyUserTripCompleted(tripId: String, trip: Trip?) {
        TripBookingService.shared.updateTripStatus(tripId, status: .completed)

        if let trip = trip {
            NotificationService.shared.scheduleTripCompletedNotification(for: trip)
            NotificationCenter.default.post(
                name: .showTripRating,
                object: nil,
                userInfo: [
                    "trip_id": tripId,
                    "trip": trip
                ]
            )
        } else {
            NotificationCenter.default.post(
                name: .showTripRating,
                object: nil,
                userInfo: ["trip_id": tripId]
            )
        }

        NotificationCenter.default.post(
            name: .adminTripCompleted,
            object: nil,
            userInfo: [
                "trip_id": tripId,
                "trip": trip as Any
            ]
        )
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

    func exportData(format: ExportFormat, options: ExportOptions) -> Data? {
        // Filter data based on options
        var filteredTrips = allTrips.filter { trip in
            trip.createdAt >= options.startDate && trip.createdAt <= options.endDate
        }

        var filteredUsers = allUsers.filter { user in
            user.dateCreated >= options.startDate && user.dateCreated <= options.endDate
        }

        switch format {
        case .csv:
            return generateCSVData(trips: filteredTrips, users: filteredUsers, options: options)
        case .json:
            return generateJSONData(trips: filteredTrips, users: filteredUsers, options: options)
        case .pdf:
            return generatePDFData(trips: filteredTrips, users: filteredUsers, options: options)
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

    private func generateCSVData(trips: [Trip], users: [User], options: ExportOptions) -> Data? {
        var csvContent = ""

        // Add users if included
        if options.includeUsers {
            csvContent += "USERS\n"
            csvContent += "User ID,Name,Email,Total Trips,Total Spent,Date Created\n"
            for user in users {
                csvContent += "\(user.id),\(user.fullName),\(user.email ?? ""),\(user.totalTrips),\(user.totalSpent),\(user.dateCreated)\n"
            }
            csvContent += "\n"
        }

        // Add trips if included
        if options.includeTrips {
            csvContent += "TRIPS\n"
            csvContent += "Trip ID,User ID,Pickup,Destination,Fare,Status,Date\n"
            for trip in trips {
                csvContent += "\(trip.id),\(trip.userId),\(trip.pickupLocation.address),\(trip.destinationLocation.address),\(trip.estimatedFare),\(trip.status.rawValue),\(trip.createdAt)\n"
            }
            csvContent += "\n"
        }

        // Add financials if included
        if options.includeFinancials {
            csvContent += "FINANCIALS\n"
            let totalRevenue = trips.reduce(0) { $0 + ($1.actualFare ?? $1.estimatedFare) }
            let commission = totalRevenue * commissionRate
            csvContent += "Total Revenue,\(totalRevenue)\n"
            csvContent += "Commission,\(commission)\n"
            csvContent += "Net Revenue,\(totalRevenue - commission)\n"
        }

        return csvContent.data(using: .utf8)
    }

    private func generateJSONData(trips: [Trip], users: [User], options: ExportOptions) -> Data? {
        var exportData: [String: Any] = [
            "generated_at": Date(),
            "start_date": options.startDate,
            "end_date": options.endDate
        ]

        if options.includeUsers {
            exportData["users"] = users.map { user in
                [
                    "id": user.id,
                    "name": user.fullName,
                    "email": user.email ?? "",
                    "total_trips": user.totalTrips,
                    "total_spent": user.totalSpent
                ]
            }
        }

        if options.includeTrips {
            exportData["trips"] = trips.map { trip in
                [
                    "id": trip.id,
                    "user_id": trip.userId,
                    "status": trip.status.rawValue,
                    "fare": trip.estimatedFare,
                    "created_at": trip.createdAt
                ]
            }
        }

        if options.includeFinancials {
            let totalRevenue = trips.reduce(0) { $0 + ($1.actualFare ?? $1.estimatedFare) }
            exportData["financials"] = [
                "total_revenue": totalRevenue,
                "commission": totalRevenue * commissionRate,
                "net_revenue": totalRevenue * (1 - commissionRate)
            ]
        }

        return try? JSONSerialization.data(withJSONObject: exportData)
    }

    private func generatePDFData(trips: [Trip], users: [User], options: ExportOptions) -> Data? {
        var pdfContent = "COMFORTA EXPORT REPORT\n\n"
        pdfContent += "Generated: \(Date())\n"
        pdfContent += "Period: \(options.startDate) to \(options.endDate)\n\n"

        if options.includeUsers {
            pdfContent += "USERS: \(users.count)\n\n"
        }

        if options.includeTrips {
            pdfContent += "TRIPS: \(trips.count)\n\n"
        }

        if options.includeFinancials {
            let totalRevenue = trips.reduce(0) { $0 + ($1.actualFare ?? $1.estimatedFare) }
            pdfContent += "FINANCIALS\n"
            pdfContent += "Total Revenue: €\(totalRevenue)\n"
            pdfContent += "Commission: €\(totalRevenue * commissionRate)\n"
        }

        return pdfContent.data(using: .utf8)
    }

    // MARK: - Notifications

    private func sendNewTripNotification(_ trip: AdminTripDTO) {
        let content = UNMutableNotificationContent()
        content.title = "🚕 Nueva Solicitud de Viaje"
        content.body = "Destino: \(trip.destino)\nPrecio: €\(String(format: "%.2f", trip.precioTotal ?? 0))"
        content.sound = .defaultCritical
        content.categoryIdentifier = "TRIP_REQUEST"
        content.userInfo = [
            "type": "new_trip_request",
            "trip_id": trip.id,
            "destination": trip.destino
        ]

        let request = UNNotificationRequest(
            identifier: "trip_\(trip.id)",
            content: content,
            trigger: nil // Immediate notification
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending notification: \(error)")
            } else {
                print("✅ Notification sent for trip: \(trip.id)")
            }
        }

        // Also play haptic feedback
        Task { @MainActor in
            HapticManager.shared.notification(.warning)
        }
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }

    func fetchTripDetail(_ tripId: String) async -> Trip? {
        do {
            let response: AdminTripResponse = try await apiClient.request(
                endpoint: .adminTripDetail(id: tripId),
                method: .get,
                requiresAuth: false
            )

            let tripDTO = response.trip
            let mappedTrip = mapAdminTrip(tripDTO)

            await MainActor.run {
                if let index = adminTripSnapshots.firstIndex(where: { $0.id == tripId }) {
                    adminTripSnapshots[index] = tripDTO
                } else {
                    adminTripSnapshots.insert(tripDTO, at: 0)
                }

                allTrips = adminTripSnapshots.map { mapAdminTrip($0) }
                refreshDerivedData()
                persistAdminCache()
            }

            return mappedTrip
        } catch {
            print("❌ Error fetching admin trip detail: \(error)")
            return nil
        }
    }

    private func persistAdminCache() {
        if let tripsData = try? JSONEncoder().encode(adminTripSnapshots) {
            UserDefaults.standard.set(tripsData, forKey: adminTripsStorageKey)
        }

        if let usersData = try? JSONEncoder().encode(adminUserSnapshots) {
            UserDefaults.standard.set(usersData, forKey: adminUsersStorageKey)
        }
    }

    private func restoreAdminCache() {
        if let tripsData = UserDefaults.standard.data(forKey: adminTripsStorageKey),
           let trips = try? JSONDecoder().decode([AdminTripDTO].self, from: tripsData) {
            adminTripSnapshots = trips
        }

        if let usersData = UserDefaults.standard.data(forKey: adminUsersStorageKey),
           let users = try? JSONDecoder().decode([AdminUserDTO].self, from: usersData) {
            adminUserSnapshots = users
        }

        if adminTripSnapshots.isEmpty && adminUserSnapshots.isEmpty {
            return
        }

        allTrips = adminTripSnapshots.map { mapAdminTrip($0) }
        allUsers = adminUserSnapshots.map { mapAdminUser($0) }
        refreshDerivedData()
        previousTripIds = Set(adminTripSnapshots.map { $0.id })
        newTripsCount = 0
    }
}
