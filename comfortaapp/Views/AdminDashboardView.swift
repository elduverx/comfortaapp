import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var selectedTab = 0
    @State private var showingUserDetails = false
    @State private var selectedUser: User?
    @State private var showingTripDetails = false
    @State private var selectedTrip: Trip?
    @State private var actionFeedback: AdminActionFeedback?
    @State private var pendingTripId: String?

    // Settings Views States
    @State private var showingPricingSettings = false
    @State private var showingVehicleTypes = false
    @State private var showingNotificationSettings = false
    @State private var showingSuspendedUsers = false
    @State private var showingReports = false
    @State private var showingSecuritySettings = false
    @State private var showingAdvancedReports = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            tabContainer(title: "Dashboard") {
                dashboardTab
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(0)

            tabContainer(title: "Usuarios") {
                usersTab
            }
            .tabItem {
                Label("Usuarios", systemImage: "person.3.fill")
            }
            .tag(1)

            tabContainer(title: "Viajes") {
                tripsTab
            }
            .tabItem {
                Label("Viajes", systemImage: "car.fill")
            }
            .tag(2)
            .badgeIf(adminService.newTripsCount > 0, count: adminService.newTripsCount)

            tabContainer(title: "Finanzas") {
                financesTab
            }
            .tabItem {
                Label("Finanzas", systemImage: "eurosign.circle.fill")
            }
            .tag(3)

            tabContainer(title: "Perfil") {
                profileTab
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle")
            }
            .tag(4)
        }
        .accentColor(ComfortaDesign.Colors.primaryGreen)
        .onAppear {
            adminService.loadDashboardData()
            adminService.requestNotificationPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAdminTripDetails)) { notification in
            guard let tripId = notification.userInfo?["trip_id"] as? String else { return }
            pendingTripId = tripId
            selectedTab = 2
            adminService.startAutoRefresh()
            adminService.newTripsCount = 0

            if let trip = adminService.allTrips.first(where: { $0.id == tripId }) {
                selectedTrip = trip
                showingTripDetails = true
                pendingTripId = nil
            }

            Task {
                if let trip = await adminService.fetchTripDetail(tripId) {
                    await MainActor.run {
                        selectedTrip = trip
                        showingTripDetails = true
                        pendingTripId = nil
                    }
                } else {
                    adminService.loadDashboardData()
                }
            }
        }
        .onReceive(adminService.$allTrips) { _ in
            openPendingTripIfPossible()
        }
        .onChange(of: selectedTab) { newTab in
            // Enable auto-refresh when viewing Trips tab
            if newTab == 2 {
                adminService.startAutoRefresh()
                // Reset new trips count when viewing trips tab
                adminService.newTripsCount = 0
            } else {
                adminService.stopAutoRefresh()
            }
        }
        .onDisappear {
            adminService.stopAutoRefresh()
        }
        .sheet(isPresented: $showingUserDetails) {
            if let user = selectedUser {
                AdminUserDetailsView(user: user)
            }
        }
        .sheet(isPresented: $showingTripDetails) {
            if let trip = selectedTrip {
                TripDetailsAdminView(trip: trip, onAction: { action in
                    handleTripAction(action, for: trip)
                })
            }
        }
        .sheet(isPresented: $showingPricingSettings) {
            AdminPricingSettingsView()
        }
        .sheet(isPresented: $showingVehicleTypes) {
            AdminVehicleTypesView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            AdminNotificationsSettingsView()
        }
        .sheet(isPresented: $showingSuspendedUsers) {
            AdminSuspendedUsersView()
        }
        .sheet(isPresented: $showingReports) {
            AdminReportsView()
        }
        .sheet(isPresented: $showingSecuritySettings) {
            AdminSecuritySettingsView()
        }
        .sheet(isPresented: $showingAdvancedReports) {
            AdminAdvancedReportsView()
        }
        .alert(item: $actionFeedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }
    
    private func tabContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationView {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .background(ComfortaDesign.Colors.background.ignoresSafeArea())
        }
    }

    private func openPendingTripIfPossible() {
        guard let tripId = pendingTripId else { return }
        guard let trip = adminService.allTrips.first(where: { $0.id == tripId }) else { return }
        selectedTrip = trip
        showingTripDetails = true
        pendingTripId = nil
    }
    
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ComfortaDesign.Spacing.md) {
                ForEach(AdminQuickAction.allCases, id: \.self) { action in
                    AdminQuickActionButton(
                        title: action.title,
                        subtitle: action.subtitle,
                        icon: action.icon,
                        colors: action.gradient
                    ) {
                        handleQuickAction(action)
                    }
                }
            }
            .padding(.vertical, ComfortaDesign.Spacing.xs)
        }
    }

    private var systemStatusSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Salud del Sistema")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Última sincronización: \(DateFormatter.shortDateFormatter.string(from: adminService.systemStatus.lastSync))")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    StatusPill(
                        text: adminService.systemStatus.incidentsToday == 0 ? "Estable" : "Incidencias",
                        color: adminService.systemStatus.incidentsToday == 0 ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.warning
                    )
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    SystemStatusMetric(title: "Uptime", value: String(format: "%.2f%%", adminService.systemStatus.uptimePercentage), icon: "clock.arrow.circlepath")
                    SystemStatusMetric(title: "Respuesta", value: "\(Int(adminService.systemStatus.averageResponseTime)) ms", icon: "bolt.horizontal.circle")
                    SystemStatusMetric(title: "Incidencias", value: "\(adminService.systemStatus.incidentsToday)", icon: "exclamationmark.triangle")
                    SystemStatusMetric(title: "Pagos", value: adminService.systemStatus.paymentsOperational ? "Operativo" : "Fallo", icon: "creditcard")
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    ServiceStatusIcon(title: "Tracking", isOnline: adminService.systemStatus.realtimeOperational)
                    ServiceStatusIcon(title: "Mapas", isOnline: adminService.systemStatus.mapsOperational)
                    ServiceStatusIcon(title: "Pagos", isOnline: adminService.systemStatus.paymentsOperational)
                }
            }
        }
    }

    private var alertsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Text("Alertas Prioritarias")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    Spacer()
                    Button("Marcar todas") {
                        adminService.criticalAlerts.forEach { adminService.resolveAlert($0.id) }
                    }
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
                
                if adminService.criticalAlerts.isEmpty {
                    Text("Sin alertas activas")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                } else {
                    LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
                        ForEach(adminService.criticalAlerts) { alert in
                            AlertRow(alert: alert) {
                                adminService.resolveAlert(alert.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var driverLeaderboardSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Top Conductores")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(adminService.topDrivers) { driver in
                        DriverPerformanceRow(driver: driver)
                    }
                }
            }
        }
    }

    private var supportTicketsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Text("Tickets de Soporte")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    Spacer()
                    Button("Ver todos") {
                        selectedTab = 1
                        actionFeedback = AdminActionFeedback(
                            title: "Soporte",
                            message: "Dirigete a la pestaña de Usuarios para gestionar los casos detallados."
                        )
                    }
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
                
                LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(adminService.supportTickets) { ticket in
                        SupportTicketRow(ticket: ticket) { status in
                            adminService.updateTicket(ticket.id, status: status)
                        }
                    }
                }
            }
        }
    }
    
    private func handleQuickAction(_ action: AdminQuickAction) {
        switch action {
        case .verifyDrivers:
            selectedTab = 1
            adminService.selectedUserFilter = .drivers
            actionFeedback = AdminActionFeedback(title: "Conductores", message: "Filtrando conductores para revisión.")
        case .reviewTickets:
            selectedTab = 0
            actionFeedback = AdminActionFeedback(title: "Tickets", message: "Revisa el bloque de soporte para más detalles.")
        case .refreshData:
            adminService.loadDashboardData()
            actionFeedback = AdminActionFeedback(title: "Actualizado", message: "El panel se sincronizó con los últimos datos.")
        case .activateSurge:
            PricingService.shared.surgeMultiplier = 1.6
            PricingService.shared.isHighDemandPeriod = true
            AnalyticsService.shared.track(.surgeActivated, metadata: ["source": "admin_panel"])
            actionFeedback = AdminActionFeedback(title: "Tarifa dinámica", message: "Se aplicó un multiplicador x1.6 temporal.")
        }
        HapticManager.shared.impact(.light)
    }

    private func handleTripAction(_ action: TripAdminAction, for trip: Trip) {
        Task {
            switch action {
            case .accept:
                await adminService.acceptTrip(trip.id)
                showingTripDetails = false
                actionFeedback = AdminActionFeedback(title: "Viaje Aceptado", message: "El viaje ha sido aceptado exitosamente.")
            case .reject:
                await adminService.rejectTrip(trip.id, reason: "Rechazado por administrador")
                showingTripDetails = false
                actionFeedback = AdminActionFeedback(title: "Viaje Rechazado", message: "El viaje ha sido rechazado.")
            case .cancel:
                await adminService.cancelTrip(trip.id, reason: "Cancelado por administrador")
                showingTripDetails = false
                actionFeedback = AdminActionFeedback(title: "Viaje Cancelado", message: "El viaje ha sido cancelado.")
            case .complete:
                await adminService.completeTrip(trip.id)
                showingTripDetails = false
                actionFeedback = AdminActionFeedback(title: "Viaje Completado", message: "El viaje ha sido marcado como completado.")
            case .assignDriver(let driverId, let driverName):
                await adminService.assignDriver(trip.id, driverId: driverId, driverName: driverName)
                showingTripDetails = false
                actionFeedback = AdminActionFeedback(title: "Conductor Asignado", message: "El conductor \(driverName) ha sido asignado al viaje.")
            }
        }
    }

    // MARK: - Dashboard Tab
    
    private var dashboardTab: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                // Quick Actions & Key Metrics
                quickActionsSection
                metricsGrid
                systemStatusSection
                
                // Charts
                revenueChart
                tripsChart
                
                // Recent Activity
                alertsSection
                driverLeaderboardSection
                supportTicketsSection
                recentActivitySection
            }
            .padding(ComfortaDesign.Spacing.lg)
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
            MetricCard(
                title: "Usuarios Activos",
                value: "\(adminService.stats.totalActiveUsers)",
                change: "+\(adminService.stats.newUsersToday)",
                isPositive: true,
                icon: "person.3.fill"
            )
            
            MetricCard(
                title: "Viajes Hoy",
                value: "\(adminService.stats.tripsToday)",
                change: "+\(adminService.stats.tripGrowthPercent)%",
                isPositive: adminService.stats.tripGrowthPercent > 0,
                icon: "car.fill"
            )
            
            MetricCard(
                title: "Ingresos",
                value: "€\(String(format: "%.0f", adminService.stats.totalRevenue))",
                change: "+€\(String(format: "%.0f", adminService.stats.revenueToday))",
                isPositive: true,
                icon: "eurosign.circle.fill"
            )
            
            MetricCard(
                title: "Conductores Online",
                value: "\(adminService.stats.driversOnline)",
                change: "\(String(format: "%.1f", adminService.stats.driverUtilization))%",
                isPositive: adminService.stats.driverUtilization > 80,
                icon: "person.crop.circle.badge.checkmark"
            )
        }
    }
    
    private var revenueChart: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Ingresos últimos 7 días")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                SimpleLineChart(data: adminService.revenueData.map { $0.revenue })
                    .frame(height: 200)
            }
        }
    }
    
    private var tripsChart: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Viajes por Estado")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                SimplePieChart(data: adminService.tripStatusData)
                    .frame(height: 200)
            }
        }
    }
    
    private var recentActivitySection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Actividad Reciente")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(adminService.recentActivities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
    }
    
    // MARK: - Users Tab
    
    private var usersTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            HStack {
                TextField("Buscar usuarios...", text: $adminService.userSearchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Menu("Filtrar") {
                    Button("Todos") { adminService.selectedUserFilter = .all }
                    Button("Pasajeros") { adminService.selectedUserFilter = .passengers }
                    Button("Conductores") { adminService.selectedUserFilter = .drivers }
                    Button("Activos") { adminService.selectedUserFilter = .active }
                }
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
            }
            .padding()
            
            // Users List
            List(adminService.filteredUsers) { user in
                UserRowView(user: user) {
                    selectedUser = user
                    showingUserDetails = true
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Trips Tab
    
    private var tripsTab: some View {
        VStack(spacing: 0) {
            // Trip Filters
            HStack {
                TextField("Buscar viajes...", text: $adminService.tripSearchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Menu("Estado") {
                    Button("Todos") { adminService.selectedTripStatus = nil }
                    ForEach(TripStatus.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            adminService.selectedTripStatus = status
                        }
                    }
                }
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

                // Auto-refresh indicator
                if adminService.isAutoRefreshEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            .font(.caption)
                        Text("Auto")
                            .font(.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ComfortaDesign.Colors.primaryGreen.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            // Trips List
            List(adminService.filteredTrips) { trip in
                TripRowView(trip: trip) {
                    selectedTrip = trip
                    showingTripDetails = true
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Finances Tab
    
    private var financesTab: some View {
        ScrollView {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                // Revenue Summary
                financeSummaryCards
                
                // Payment Methods
                paymentMethodsChart
                
                // Recent Transactions
                recentTransactionsSection
            }
            .padding()
        }
    }
    
    private var financeSummaryCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
            MetricCard(
                title: "Ingresos Mes",
                value: "€\(String(format: "%.0f", adminService.stats.monthlyRevenue))",
                change: "+\(String(format: "%.1f", adminService.stats.monthlyGrowth))%",
                isPositive: adminService.stats.monthlyGrowth > 0,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            MetricCard(
                title: "Comisión",
                value: "€\(String(format: "%.0f", adminService.stats.platformCommission))",
                change: "\(String(format: "%.1f", adminService.stats.commissionRate))%",
                isPositive: true,
                icon: "percent"
            )
        }
    }
    
    private var paymentMethodsChart: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Métodos de Pago")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                SimpleBarChart(data: adminService.paymentMethodData)
                    .frame(height: 200)
            }
        }
    }
    
    private var recentTransactionsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Transacciones Recientes")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(adminService.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Tab
    
    private var profileTab: some View {
        ScrollView {
            VStack(spacing: ComfortaDesign.Spacing.xl) {
                // Admin Profile Header
                adminProfileHeader
                
                // Admin Stats Grid
                adminStatsGrid
                
                // Admin Permissions
                adminPermissionsSection
                
                // Admin Settings
                adminSettingsSection
                
                // Sign Out Button
                signOutButton
            }
            .padding(ComfortaDesign.Spacing.lg)
        }
    }
    
    private var adminProfileHeader: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                // Profile Image
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.primaryGreen.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: ComfortaDesign.Colors.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: ComfortaDesign.Spacing.xs) {
                    Text("Administrador Comforta")
                        .font(ComfortaDesign.Typography.title1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Text("admin@comforta.app")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        Text("Acceso Total")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                }
                
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    VStack {
                        Text("2")
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Años activo")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Rectangle()
                        .fill(ComfortaDesign.Colors.glassBorder)
                        .frame(width: 1, height: 40)
                    
                    VStack {
                        Text("24/7")
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Disponible")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    private var adminStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
            AdminProfileCard(
                title: "Sesiones Admin",
                value: "847",
                icon: "person.badge.key",
                color: ComfortaDesign.Colors.primaryGreen
            )
            
            AdminProfileCard(
                title: "Acciones Hoy",
                value: "23",
                icon: "bolt.fill",
                color: ComfortaDesign.Colors.warning
            )
            
            AdminProfileCard(
                title: "Usuarios Gestionados",
                value: "1.2K",
                icon: "person.3.fill",
                color: ComfortaDesign.Colors.info
            )
            
            AdminProfileCard(
                title: "Reportes Resueltos",
                value: "156",
                icon: "checkmark.shield",
                color: ComfortaDesign.Colors.primaryGreen
            )
        }
    }
    
    private var adminPermissionsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Permisos de Administrador")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    PermissionRow(icon: "person.3.fill", title: "Gestión de Usuarios", isEnabled: true)
                    PermissionRow(icon: "car.fill", title: "Gestión de Viajes", isEnabled: true)
                    PermissionRow(icon: "eurosign.circle.fill", title: "Gestión Financiera", isEnabled: true)
                    PermissionRow(icon: "chart.bar.fill", title: "Análisis y Reportes", isEnabled: true)
                    PermissionRow(icon: "gear.circle.fill", title: "Configuración del Sistema", isEnabled: true)
                    PermissionRow(icon: "shield.fill", title: "Control de Seguridad", isEnabled: true)
                }
            }
        }
    }
    
    private var adminSettingsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Configuración")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    SettingRow(icon: "eurosign.circle", title: "Precios y Tarifas", action: {
                        showingPricingSettings = true
                    })
                    SettingRow(icon: "car.circle", title: "Tipos de Vehículo", action: {
                        showingVehicleTypes = true
                    })
                    SettingRow(icon: "bell.circle", title: "Notificaciones", action: {
                        showingNotificationSettings = true
                    })
                    SettingRow(icon: "person.crop.circle.badge.xmark", title: "Usuarios Suspendidos", action: {
                        showingSuspendedUsers = true
                    })
                    SettingRow(icon: "exclamationmark.triangle", title: "Reportes", action: {
                        showingReports = true
                    })
                    SettingRow(icon: "shield.checkered", title: "Seguridad", action: {
                        showingSecuritySettings = true
                    })
                    SettingRow(icon: "chart.bar", title: "Reportes Avanzados", action: {
                        showingAdvancedReports = true
                    })
                }
            }
        }
    }
    
    private var signOutButton: some View {
        Button {
            UserManager.shared.signOut()
        } label: {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("Cerrar Sesión")
            }
            .font(ComfortaDesign.Typography.body1)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [ComfortaDesign.Colors.error, ComfortaDesign.Colors.error.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(ComfortaDesign.Radius.md)
        }
    }
}

private extension View {
    @ViewBuilder
    func badgeIf(_ condition: Bool, count: Int) -> some View {
        if condition {
            badge(count)
        } else {
            self
        }
    }
}

// MARK: - Supporting Views

struct AdminProfileCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    Spacer()
                }
                
                Text(value)
                    .font(ComfortaDesign.Typography.title1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
        }
        .padding(.vertical, 4)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    
    var body: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Spacer()
                    Text(change)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(isPositive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
                }
                
                Text(value)
                    .font(ComfortaDesign.Typography.title1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(ComfortaDesign.Colors.primaryGreen)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.firstName.prefix(1)))
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Text(user.userType.displayName)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(user.totalTrips) viajes")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    Circle()
                        .fill(user.isActive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(ComfortaDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .fill(ComfortaDesign.Colors.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TripRowView: View {
    let trip: Trip
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ModernCard(style: .surface) {
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    HStack {
                        Text("#\(trip.id.prefix(8))")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)

                        Spacer()

                        Text(trip.status.displayName)
                            .font(ComfortaDesign.Typography.caption1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(statusColor.opacity(0.2))
                            )
                            .foregroundColor(statusColor)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Desde")
                                .font(ComfortaDesign.Typography.caption2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            Text(trip.pickupLocation.address)
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Hasta")
                                .font(ComfortaDesign.Typography.caption2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            Text(trip.destinationLocation.address)
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                                .lineLimit(1)
                        }
                    }

                    HStack {
                        Text("€\(trip.estimatedFare, specifier: "%.2f")")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)

                        Spacer()

                        Text(DateFormatter.shortDateFormatter.string(from: trip.createdAt))
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statusColor: Color {
        switch trip.status {
        case .completed:
            return ComfortaDesign.Colors.primaryGreen
        case .cancelled, .failed:
            return ComfortaDesign.Colors.error
        case .inProgress:
            return ComfortaDesign.Colors.warning
        default:
            return ComfortaDesign.Colors.textSecondary
        }
    }
}

struct ActivityRow: View {
    let activity: AdminActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Text(DateFormatter.timeFormatter.string(from: activity.timestamp))
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct TransactionRow: View {
    let transaction: PaymentRecord
    
    var body: some View {
        HStack {
            Image(systemName: transaction.method.iconName)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionId)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Text(transaction.method.displayName)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("€\(transaction.amount, specifier: "%.2f")")
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminQuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: ComfortaDesign.Radius.sm))
                
                Text(title)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(ComfortaDesign.Spacing.md)
            .frame(width: 180, alignment: .leading)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(ComfortaDesign.Radius.lg)
            .shadow(color: colors.last?.opacity(0.4) ?? .black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(ComfortaDesign.Typography.caption1)
            .foregroundColor(color)
            .padding(.horizontal, ComfortaDesign.Spacing.sm)
            .padding(.vertical, ComfortaDesign.Spacing.xs)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct SystemStatusMetric: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
            HStack(spacing: ComfortaDesign.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                Text(title)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
            Text(value)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
    }
}

struct ServiceStatusIcon: View {
    let title: String
    let isOnline: Bool
    
    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.xs) {
            Circle()
                .fill(isOnline ? ComfortaDesign.Colors.primaryGreen.opacity(0.2) : ComfortaDesign.Colors.error.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: isOnline ? "checkmark" : "xmark")
                        .foregroundColor(isOnline ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
                )
            Text(title)
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AlertRow: View {
    let alert: AdminAlert
    let onResolve: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: ComfortaDesign.Spacing.sm) {
            Circle()
                .fill(alert.severity.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(alert.severity.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    Spacer()
                    StatusPill(text: alert.severity == .critical ? "Crítica" : alert.severity == .warning ? "Atención" : "Aviso", color: alert.severity.color)
                }
                
                Text(alert.message)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text(DateFormatter.timeFormatter.string(from: alert.timestamp))
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    Spacer()
                    if !alert.isResolved {
                        Button("Resolver") {
                            onResolve()
                        }
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    } else {
                        Text("Resuelta")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

struct DriverPerformanceRow: View {
    let driver: DriverPerformance
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.name)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                HStack(spacing: ComfortaDesign.Spacing.sm) {
                    Label(String(format: "%.1f", driver.rating), systemImage: "star.fill")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.warning)
                    
                    Text("\(driver.completedTrips) viajes")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("€\(driver.earnings, specifier: "%.0f")")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                StatusPill(text: driver.status.label, color: driver.status.color)
            }
        }
    }
}

struct SupportTicketRow: View {
    let ticket: SupportTicket
    let onStatusChange: (TicketStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
            HStack {
                Text(ticket.reference)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                Spacer()
                StatusPill(text: ticket.priority.title, color: ticket.priority.color)
            }
            
            Text(ticket.subject)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
            
            HStack {
                Text(ticket.userName)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                Spacer()
                Menu {
                    ForEach(TicketStatus.allCases, id: \.self) { status in
                        Button(status.title) {
                            onStatusChange(status)
                        }
                    }
                } label: {
                    StatusPill(text: ticket.status.title, color: ticket.status.color)
                }
            }
        }
        .padding(ComfortaDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct AdminActionFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum AdminQuickAction: CaseIterable {
    case verifyDrivers
    case reviewTickets
    case refreshData
    case activateSurge
    
    var title: String {
        switch self {
        case .verifyDrivers: return "Verificar"
        case .reviewTickets: return "Tickets"
        case .refreshData: return "Sincronizar"
        case .activateSurge: return "Tarifa"
        }
    }
    
    var subtitle: String {
        switch self {
        case .verifyDrivers: return "Conductores nuevos"
        case .reviewTickets: return "Casos soporte"
        case .refreshData: return "Refrescar datos"
        case .activateSurge: return "Activar surge"
        }
    }
    
    var icon: String {
        switch self {
        case .verifyDrivers: return "checkmark.seal"
        case .reviewTickets: return "questionmark.circle"
        case .refreshData: return "arrow.clockwise"
        case .activateSurge: return "bolt.fill"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .verifyDrivers:
            return [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen]
        case .reviewTickets:
            return [ComfortaDesign.Colors.accent, ComfortaDesign.Colors.info]
        case .refreshData:
            return [ComfortaDesign.Colors.warning, ComfortaDesign.Colors.primaryGreen]
        case .activateSurge:
            return [ComfortaDesign.Colors.error, ComfortaDesign.Colors.warning]
        }
    }
}

// MARK: - DateFormatter Extensions

private extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Simple Chart Views

struct SimpleLineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue
            
            ZStack {
                // Background grid
                VStack {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(ComfortaDesign.Colors.glassBorder.opacity(0.3))
                        Spacer()
                    }
                }
                
                // Line path
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) / CGFloat(data.count - 1) * width
                        let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                        let y = height - (CGFloat(normalizedValue) * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(ComfortaDesign.Colors.primaryGreen, lineWidth: 3)
                .shadow(color: ComfortaDesign.Colors.primaryGreen.opacity(0.3), radius: 4)
            }
        }
    }
}

struct SimplePieChart: View {
    let data: [TripStatusData]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            let total = Double(data.reduce(0) { $0 + $1.count })
            
            ZStack {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    let percentage = Double(item.count) / total
                    let angle = percentage * 360
                    let startAngle = data[0..<index].reduce(0) { sum, d in
                        sum + (Double(d.count) / total * 360)
                    }
                    
                    PieSlice(
                        startAngle: startAngle,
                        endAngle: startAngle + angle,
                        center: center,
                        radius: radius
                    )
                    .fill(item.color)
                }
            }
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    let center: CGPoint
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle - 90),
            endAngle: .degrees(endAngle - 90),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct SimpleBarChart: View {
    let data: [PaymentMethodData]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(data, id: \.id) { item in
                VStack {
                    Spacer()
                    
                    Rectangle()
                        .fill(ComfortaDesign.Colors.primaryGreen)
                        .frame(width: 40, height: CGFloat(item.count) * 5)
                        .cornerRadius(4)
                    
                    Text(item.method)
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("\(item.count)")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Trip Admin Actions

enum TripAdminAction {
    case accept
    case reject
    case cancel
    case complete
    case assignDriver(driverId: String, driverName: String)
}

struct TripDetailsAdminView: View {
    let trip: Trip
    let onAction: (TripAdminAction) -> Void

    @State private var showingDriverAssignment = false
    @State private var driverId = ""
    @State private var driverName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    // Trip Status
                    statusSection

                    // Trip Details
                    tripDetailsSection

                    // Actions - Show different actions based on trip status
                    if trip.status == .requested || trip.status == .scheduled {
                        requestedActionsSection
                    } else if trip.status == .driverAssigned || trip.status == .driverEnRoute || trip.status == .driverArrived || trip.status == .inProgress {
                        inProgressActionsSection
                    }

                    Spacer()
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Detalle de Viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Estado del Viaje")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text(trip.status.displayName)
                    .font(ComfortaDesign.Typography.title2)
                    .foregroundColor(statusColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.2))
                    )
            }
        }
    }

    private var tripDetailsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Información del Viaje")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                detailRow(title: "ID", value: trip.id.prefix(8).description, icon: "number")
                detailRow(title: "Desde", value: trip.pickupLocation.address, icon: "location.circle")
                detailRow(title: "Hasta", value: trip.destinationLocation.address, icon: "mappin.circle")
                detailRow(title: "Tarifa Estimada", value: String(format: "€%.2f", trip.estimatedFare), icon: "eurosign.circle")
                detailRow(title: "Distancia", value: String(format: "%.1f km", trip.estimatedDistance), icon: "ruler")
                detailRow(title: "Fecha", value: DateFormatter.shortDateFormatter.string(from: trip.createdAt), icon: "calendar")
            }
        }
    }

    private var requestedActionsSection: some View {
        ModernCard(style: .surface) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Acciones")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                // Accept Button
                Button {
                    onAction(.accept)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Aceptar Viaje")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.primaryGreen)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }

                // Assign Driver Button
                Button {
                    showingDriverAssignment = true
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text("Asignar Conductor")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.info)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }

                // Reject Button
                Button {
                    onAction(.reject)
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Rechazar Viaje")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.error)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }
            }
        }
        .alert("Asignar Conductor", isPresented: $showingDriverAssignment) {
            TextField("ID del Conductor", text: $driverId)
            TextField("Nombre del Conductor", text: $driverName)
            Button("Cancelar", role: .cancel) {}
            Button("Asignar") {
                if !driverId.isEmpty && !driverName.isEmpty {
                    onAction(.assignDriver(driverId: driverId, driverName: driverName))
                }
            }
        } message: {
            Text("Ingresa los datos del conductor a asignar")
        }
    }

    private var inProgressActionsSection: some View {
        ModernCard(style: .surface) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Acciones")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                // Complete Button
                Button {
                    onAction(.complete)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Completar Viaje")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.primaryGreen)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }

                // Cancel Button
                Button {
                    onAction(.cancel)
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancelar Viaje")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.error)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }
            }
        }
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                .frame(width: 24)

            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
    }

    private var statusColor: Color {
        switch trip.status {
        case .completed:
            return ComfortaDesign.Colors.primaryGreen
        case .cancelled, .failed:
            return ComfortaDesign.Colors.error
        case .inProgress:
            return ComfortaDesign.Colors.warning
        case .requested, .scheduled:
            return ComfortaDesign.Colors.info
        default:
            return ComfortaDesign.Colors.textSecondary
        }
    }
}

#Preview {
    AdminDashboardView()
}
