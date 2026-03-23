import SwiftUI
import Foundation
import UserNotifications

// MARK: - Enhanced Pricing Settings View

struct AdminPricingSettingsViewEnhanced: View {
    @StateObject private var viewModel: AdminPricingViewModel
    @Environment(\.dismiss) private var dismiss

    init() {
        _viewModel = StateObject(wrappedValue: AdminPricingViewModel(
            pricing: PricingService.shared.currentPricing
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: ComfortaDesign.Spacing.lg) {
                        // Impact preview card
                        if viewModel.hasChanges, let impact = viewModel.calculateImpact() {
                            impactPreviewCard(impact)
                        }

                        // Base Rates Section
                        baseRatesSection

                        // Minimum Fares Section
                        minimumFaresSection

                        // Additional Charges Section
                        additionalChargesSection

                        // Vehicle Multipliers Section
                        vehicleMultipliersSection

                        // Commission Section
                        commissionSection

                        // Action Buttons
                        actionButtons
                    }
                    .padding(ComfortaDesign.Spacing.lg)
                }

                if viewModel.isSaving {
                    LoadingOverlay(message: "Guardando cambios...")
                }
            }
            .navigationTitle("Precios y Tarifas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        if viewModel.hasChanges {
                            showCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Historial") {
                        showingAuditLog = true
                    }
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
            }
            .sheet(isPresented: $showingComparison) {
                PricingComparisonView(
                    currentPricing: PricingService.shared.currentPricing,
                    newPricing: viewModel.pricing,
                    impact: viewModel.calculateImpact()
                )
            }
            .sheet(isPresented: $showingAuditLog) {
                AuditLogView()
            }
        }
    }

    @State private var showingComparison = false
    @State private var showingAuditLog = false
    @State private var showCancelConfirmation = false

    private func impactPreviewCard(_ impact: PricingImpact) -> some View {
        ModernCard(style: .glass) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Impacto Estimado")
                            .font(ComfortaDesign.Typography.headline)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)

                        Text("Viaje promedio 10km")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }

                    Spacer()

                    Text(impact.impactDescription)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(impact.impactColor)
                        .bold()
                }

                Button {
                    showingComparison = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Ver Comparación Completa")
                    }
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
            }
        }
    }

    private var baseRatesSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Tarifas Base")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ValidatedPriceInputRow(
                    title: "Tarifa Base",
                    value: $viewModel.pricing.baseFare,
                    unit: "€",
                    range: 0...50,
                    fieldKey: "baseFare",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )

                ValidatedPriceInputRow(
                    title: "Por Kilómetro",
                    value: $viewModel.pricing.perKilometerRate,
                    unit: "€/km",
                    range: 0...10,
                    fieldKey: "perKilometerRate",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )

                ValidatedPriceInputRow(
                    title: "Por Minuto",
                    value: $viewModel.pricing.perMinuteRate,
                    unit: "€/min",
                    range: 0...5,
                    fieldKey: "perMinuteRate",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )
            }
        }
    }

    private var minimumFaresSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Tarifas Mínimas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ValidatedPriceInputRow(
                    title: "Tarifa Mínima General",
                    value: $viewModel.pricing.minimumFare,
                    unit: "€",
                    range: 0...100,
                    fieldKey: "minimumFare",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )

                ValidatedPriceInputRow(
                    title: "Tarifa Mínima Viajes Largos",
                    value: $viewModel.pricing.minimumFareForLongTrips,
                    unit: "€",
                    range: 0...200,
                    fieldKey: "minimumFareForLongTrips",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )

                ValidatedPriceInputRow(
                    title: "Umbral Viaje Largo",
                    value: $viewModel.pricing.minimumFareThreshold,
                    unit: "km",
                    range: 0...50,
                    fieldKey: "minimumFareThreshold",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )
            }
        }
    }

    private var additionalChargesSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Recargos Adicionales")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ValidatedPriceInputRow(
                    title: "Recargo Aeropuerto",
                    value: $viewModel.pricing.airportSurcharge,
                    unit: "€",
                    range: 0...50,
                    fieldKey: "airportSurcharge",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )
            }
        }
    }

    private var vehicleMultipliersSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Multiplicadores por Vehículo")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ForEach(Array(viewModel.pricing.vehicleMultipliers.keys.sorted()), id: \.self) { vehicleType in
                    ValidatedPriceInputRow(
                        title: vehicleTypeName(vehicleType),
                        value: Binding(
                            get: { viewModel.pricing.vehicleMultipliers[vehicleType] ?? 1.0 },
                            set: { viewModel.pricing.vehicleMultipliers[vehicleType] = $0 }
                        ),
                        unit: "x",
                        range: 0.5...5.0,
                        fieldKey: "multiplier_\(vehicleType)",
                        validationErrors: viewModel.validationErrors,
                        onChange: { viewModel.validateAll() }
                    )
                }
            }
        }
    }

    private var commissionSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Comisión de Plataforma")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ValidatedPriceInputRow(
                    title: "Tasa de Comisión",
                    value: $viewModel.pricing.commissionRate,
                    unit: "%",
                    range: 0...100,
                    fieldKey: "commissionRate",
                    validationErrors: viewModel.validationErrors,
                    onChange: { viewModel.validateAll() }
                )
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.hasChanges {
                Button {
                    showingComparison = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Ver Impacto de Cambios")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                            .stroke(ComfortaDesign.Colors.primaryGreen, lineWidth: 2)
                    )
                }
                .accessibilityLabel("Ver impacto de cambios de precios")
                .accessibilityHint("Muestra una comparación detallada antes y después de los cambios")
            }

            Button {
                saveChanges()
            } label: {
                Text("Guardar Cambios")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        viewModel.hasChanges && viewModel.isValid ?
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.textSecondary, ComfortaDesign.Colors.textSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(ComfortaDesign.Radius.md)
            }
            .disabled(!viewModel.hasChanges || !viewModel.isValid)
            .accessibilityLabel("Guardar cambios de precios")
            .accessibilityHint("Guardará las nuevas tarifas y multiplicadores en el sistema")
            .accessibilityAddTraits(.isButton)

            if viewModel.hasChanges {
                Button {
                    viewModel.reset()
                } label: {
                    Text("Descartar Cambios")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.error)
                }
            }
        }
    }

    private func saveChanges() {
        Task {
            let success = await viewModel.save()
            if success {
                HapticManager.shared.notification(.success)

                // Send notification
                AdminNotificationManager.shared.sendBulkNotification(
                    title: "✅ Precios Actualizados",
                    body: "La estructura de precios ha sido modificada"
                )

                await MainActor.run {
                    dismiss()
                }
            } else {
                HapticManager.shared.notification(.error)
            }
        }
    }

    private func vehicleTypeName(_ type: String) -> String {
        switch type {
        case "sedan": return "Sedán"
        case "suv": return "SUV"
        case "van": return "Van"
        case "luxury": return "Lujo"
        default: return type.capitalized
        }
    }
}

// MARK: - Enhanced Suspended Users View

struct AdminSuspendedUsersViewEnhanced: View {
    @StateObject private var viewModel = SuspendedUsersViewModel()
    @State private var selectedUser: SuspendedUser?
    @State private var showingUserDetails = false
    @State private var showingConfirmation = false
    @State private var confirmationAction: SuspendedUserAction?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    TextField("Buscar usuarios...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Buscar usuarios suspendidos")
                }
                .padding(12)
                .background(ComfortaDesign.Colors.surface)
                .cornerRadius(ComfortaDesign.Radius.sm)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Filters
                filtersSection

                // Users List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredUsers.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredUsers) { user in
                                SuspendedUserCard(user: user) {
                                    selectedUser = user
                                    showingUserDetails = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Usuarios Suspendidos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SuspendedUsersViewModel.SortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingUserDetails) {
                if let user = selectedUser {
                    enhancedUserDetailView(user: user)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadUsers()
                }
            }
        }

        if showingConfirmation, let action = confirmationAction, let user = selectedUser {
            confirmationDialog(for: action, user: user)
        }
    }

    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SuspendedUsersViewModel.FilterOption.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.filterOption == filter
                    ) {
                        viewModel.filterOption = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            Text("No hay usuarios suspendidos")
                .font(ComfortaDesign.Typography.title2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            if !viewModel.searchText.isEmpty {
                Text("No se encontraron resultados para '\(viewModel.searchText)'")
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Limpiar búsqueda") {
                    viewModel.searchText = ""
                }
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
            } else {
                Text("Todos los usuarios están en buen estado")
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func enhancedUserDetailView(user: SuspendedUser) -> some View {
        SuspendedUserDetailView(user: user) { action in
            selectedUser = user
            confirmationAction = action
            showingConfirmation = true
            showingUserDetails = false
        }
    }

    private func confirmationDialog(for action: SuspendedUserAction, user: SuspendedUser) -> some View {
        Group {
            switch action {
            case .reactivate:
                ConfirmationDialog(
                    title: "Reactivar Usuario",
                    message: "¿Estás seguro de que deseas reactivar a \(user.name)?",
                    confirmButtonText: "Reactivar",
                    confirmationKeyword: nil,
                    isDestructive: false,
                    isPresented: $showingConfirmation
                ) {
                    Task {
                        await viewModel.reactivateUser(user.id)
                        AdminNotificationManager.shared.sendBulkNotification(
                            title: "✅ Usuario Reactivado",
                            body: "\(user.name) ha sido reactivado"
                        )
                    }
                }

            case .permanentBan:
                ConfirmationDialog(
                    title: "Baneo Permanente",
                    message: "Esta acción NO se puede deshacer. El usuario \(user.name) será baneado permanentemente.",
                    confirmButtonText: "Banear",
                    confirmationKeyword: "BANEAR",
                    isDestructive: true,
                    isPresented: $showingConfirmation
                ) {
                    Task {
                        await viewModel.permanentBan(user.id)
                        AdminNotificationManager.shared.sendBulkNotification(
                            title: "🚫 Usuario Baneado",
                            body: "\(user.name) ha sido baneado permanentemente"
                        )
                    }
                }

            case .contactUser:
                ConfirmationDialog(
                    title: "Contactar Usuario",
                    message: "Se abrirá la aplicación de email para contactar a \(user.name)",
                    confirmButtonText: "Continuar",
                    confirmationKeyword: nil,
                    isDestructive: false,
                    isPresented: $showingConfirmation
                ) {
                    // Open email client
                    if let emailURL = URL(string: "mailto:\(user.email)") {
                        UIApplication.shared.open(emailURL)
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Reports View with Export

struct AdminReportsViewEnhanced: View {
    @StateObject private var exportVM = ExportViewModel()
    @State private var showingExportOptions = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: ComfortaDesign.Spacing.lg) {
                        // Quick stats
                        quickStatsSection

                        // Export options card
                        exportOptionsCard

                        // Recent exports
                        recentExportsSection
                    }
                    .padding(ComfortaDesign.Spacing.lg)
                }

                if exportVM.isExporting {
                    LoadingOverlay(
                        message: "Exportando datos...",
                        progress: exportVM.exportProgress
                    )
                }
            }
            .navigationTitle("Reportes y Exportación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("Error de Exportación", isPresented: .constant(exportVM.exportError != nil)) {
                Button("OK") {
                    exportVM.exportError = nil
                }
            } message: {
                if let error = exportVM.exportError {
                    Text(error)
                }
            }
        }
    }

    private var quickStatsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Resumen de Datos")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    AdminStatCard(title: "Usuarios", value: "\(AdminService.shared.allUsers.count)", icon: "person.3.fill")
                    AdminStatCard(title: "Viajes", value: "\(AdminService.shared.allTrips.count)", icon: "car.fill")
                    AdminStatCard(title: "Ingresos", value: String(format: "€%.0f", AdminService.shared.stats.totalRevenue), icon: "eurosign.circle")
                    AdminStatCard(title: "Comisión", value: String(format: "€%.0f", AdminService.shared.stats.platformCommission), icon: "percent")
                }
            }
        }
    }

    private var exportOptionsCard: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.lg) {
                Text("Configurar Exportación")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                // Date range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rango de Fechas")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    DatePicker("Desde", selection: $exportVM.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    DatePicker("Hasta", selection: $exportVM.endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                // Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Incluir en Exportación")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    Toggle("Datos de Usuarios", isOn: $exportVM.includeUserData)
                    Toggle("Viajes", isOn: $exportVM.includeTrips)
                    Toggle("Información Financiera", isOn: $exportVM.includeFinancials)
                }

                // Format selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Formato")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    HStack(spacing: 12) {
                        ForEach([ExportFormat.csv, .json, .pdf], id: \.self) { format in
                            formatButton(format)
                        }
                    }
                }

                // Export button
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Exportar Datos")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        exportVM.isValid ?
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.textSecondary, ComfortaDesign.Colors.textSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(ComfortaDesign.Radius.md)
                }
                .disabled(!exportVM.isValid)
                .accessibilityLabel("Exportar datos")
                .accessibilityHint("Exporta los datos seleccionados en el formato especificado")
            }
        }
    }

    private func formatButton(_ format: ExportFormat) -> some View {
        Button {
            exportVM.selectedFormat = format
        } label: {
            Text(formatName(format))
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(exportVM.selectedFormat == format ? .white : ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    exportVM.selectedFormat == format ?
                        ComfortaDesign.Colors.primaryGreen :
                        ComfortaDesign.Colors.surface
                )
                .cornerRadius(ComfortaDesign.Radius.sm)
        }
    }

    private func formatName(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        }
    }

    private var recentExportsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Text("Exportaciones Recientes")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    Spacer()

                    Button {
                        // Open audit log
                    } label: {
                        Text("Ver Todas")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    }
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ForEach(0..<3) { index in
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export_\(Date().timeIntervalSince1970 - Double(index * 86400), specifier: "%.0f").csv")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)

                            Text("\(formatDate(daysAgo: index))")
                                .font(ComfortaDesign.Typography.caption2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }

                        Spacer()

                        Text("CSV")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(ComfortaDesign.Colors.surface))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func exportData() {
        Task {
            let success = await exportVM.exportWithOptions()
            if success {
                HapticManager.shared.notification(.success)

                AdminNotificationManager.shared.sendBulkNotification(
                    title: "✅ Exportación Completada",
                    body: "Los datos han sido exportados exitosamente"
                )

                AnalyticsService.shared.track(.reportExported, metadata: [
                    "format": formatName(exportVM.selectedFormat),
                    "users": exportVM.includeUserData ? "yes" : "no",
                    "trips": exportVM.includeTrips ? "yes" : "no",
                    "financials": exportVM.includeFinancials ? "yes" : "no"
                ])
            }
        }
    }

    private func formatDate(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                .font(.title3)

            Text(value)
                .font(ComfortaDesign.Typography.title2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}
