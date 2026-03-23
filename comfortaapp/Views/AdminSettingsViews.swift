import SwiftUI
import Foundation
import UserNotifications

// MARK: - Pricing Settings View

struct AdminPricingSettingsView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var pricingStructure: PricingStructure
    @State private var showingSaveConfirmation = false
    @State private var hasChanges = false
    @Environment(\.dismiss) private var dismiss

    init() {
        _pricingStructure = State(initialValue: PricingService.shared.currentPricing)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
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

                    // Save Button
                    saveButton
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Precios y Tarifas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        savePricing()
                    }
                    .disabled(!hasChanges)
                    .foregroundColor(hasChanges ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.textSecondary)
                }
            }
            .alert("Precios Actualizados", isPresented: $showingSaveConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("La estructura de precios ha sido actualizada exitosamente.")
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

                PriceInputRow(
                    title: "Tarifa Base",
                    value: $pricingStructure.baseFare,
                    unit: "€",
                    onChange: { hasChanges = true }
                )

                PriceInputRow(
                    title: "Por Kilómetro",
                    value: $pricingStructure.perKilometerRate,
                    unit: "€/km",
                    onChange: { hasChanges = true }
                )

                PriceInputRow(
                    title: "Por Minuto",
                    value: $pricingStructure.perMinuteRate,
                    unit: "€/min",
                    onChange: { hasChanges = true }
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

                PriceInputRow(
                    title: "Tarifa Mínima General",
                    value: $pricingStructure.minimumFare,
                    unit: "€",
                    onChange: { hasChanges = true }
                )

                PriceInputRow(
                    title: "Tarifa Mínima Viajes Largos",
                    value: $pricingStructure.minimumFareForLongTrips,
                    unit: "€",
                    onChange: { hasChanges = true }
                )

                PriceInputRow(
                    title: "Umbral Viaje Largo",
                    value: $pricingStructure.minimumFareThreshold,
                    unit: "km",
                    onChange: { hasChanges = true }
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

                PriceInputRow(
                    title: "Recargo Aeropuerto",
                    value: $pricingStructure.airportSurcharge,
                    unit: "€",
                    onChange: { hasChanges = true }
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

                ForEach(Array(pricingStructure.vehicleMultipliers.keys.sorted()), id: \.self) { vehicleType in
                    MultiplierInputRow(
                        title: vehicleTypeName(vehicleType),
                        multiplier: Binding(
                            get: { pricingStructure.vehicleMultipliers[vehicleType] ?? 1.0 },
                            set: { newValue in
                                pricingStructure.vehicleMultipliers[vehicleType] = newValue
                                hasChanges = true
                            }
                        )
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

                PriceInputRow(
                    title: "Tasa de Comisión",
                    value: $pricingStructure.commissionRate,
                    unit: "%",
                    onChange: { hasChanges = true }
                )
            }
        }
    }

    private var saveButton: some View {
        Button {
            savePricing()
        } label: {
            Text("Guardar Cambios")
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    hasChanges ?
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
        .disabled(!hasChanges)
    }

    private func savePricing() {
        adminService.updatePricingStructure(pricingStructure)
        showingSaveConfirmation = true
        hasChanges = false
        HapticManager.shared.notification(.success)
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

// MARK: - Vehicle Types Settings View

struct AdminVehicleTypesView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var vehicleTypes: [VehicleTypeConfig] = VehicleTypeConfig.defaultTypes
    @State private var showingAddVehicle = false
    @State private var showingSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    ForEach($vehicleTypes) { $vehicle in
                        VehicleTypeCard(vehicle: $vehicle)
                    }

                    addVehicleButton
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Tipos de Vehículo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveVehicleTypes()
                    }
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
            }
        }
    }

    private var addVehicleButton: some View {
        Button {
            showingAddVehicle = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Agregar Tipo de Vehículo")
            }
            .font(ComfortaDesign.Typography.body1)
            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .stroke(ComfortaDesign.Colors.primaryGreen, lineWidth: 2)
            )
        }
    }

    private func saveVehicleTypes() {
        // Save vehicle types configuration
        showingSaveConfirmation = true
        HapticManager.shared.notification(.success)
        AnalyticsService.shared.track(.vehicleTypesUpdated)
    }
}

struct VehicleTypeCard: View {
    @Binding var vehicle: VehicleTypeConfig

    var body: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: vehicle.icon)
                        .font(.title2)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.name)
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)

                        Text("\(vehicle.passengerCapacity) pasajeros")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $vehicle.isActive)
                        .labelsHidden()
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    HStack {
                        Text("Multiplicador de Precio:")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1fx", vehicle.priceMultiplier))
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    }

                    HStack {
                        Text("Capacidad de Equipaje:")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Spacer()
                        Text("\(vehicle.luggageCapacity) maletas")
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    }
                }
            }
        }
    }
}

struct VehicleTypeConfig: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var passengerCapacity: Int
    var luggageCapacity: Int
    var priceMultiplier: Double
    var isActive: Bool

    static let defaultTypes: [VehicleTypeConfig] = [
        VehicleTypeConfig(name: "Sedán", icon: "car.fill", passengerCapacity: 4, luggageCapacity: 2, priceMultiplier: 1.0, isActive: true),
        VehicleTypeConfig(name: "SUV", icon: "suv.side.fill", passengerCapacity: 6, luggageCapacity: 4, priceMultiplier: 1.2, isActive: true),
        VehicleTypeConfig(name: "Van", icon: "bus.fill", passengerCapacity: 8, luggageCapacity: 6, priceMultiplier: 1.5, isActive: true),
        VehicleTypeConfig(name: "Lujo", icon: "car.side.fill", passengerCapacity: 4, luggageCapacity: 2, priceMultiplier: 2.0, isActive: true)
    ]
}

// MARK: - Notifications Settings View

struct AdminNotificationsSettingsView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var notificationSettings = NotificationSettings()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    // Trip Notifications
                    notificationSection(
                        title: "Notificaciones de Viajes",
                        icon: "car.fill",
                        settings: [
                            ("Nuevas Solicitudes", $notificationSettings.newTripRequests),
                            ("Viajes Completados", $notificationSettings.tripCompleted),
                            ("Viajes Cancelados", $notificationSettings.tripCancelled),
                            ("Viajes Modificados", $notificationSettings.tripModified)
                        ]
                    )

                    // User Notifications
                    notificationSection(
                        title: "Notificaciones de Usuarios",
                        icon: "person.3.fill",
                        settings: [
                            ("Nuevos Registros", $notificationSettings.newUserRegistration),
                            ("Usuarios Suspendidos", $notificationSettings.userSuspended),
                            ("Conductores Verificados", $notificationSettings.driverVerified)
                        ]
                    )

                    // Financial Notifications
                    notificationSection(
                        title: "Notificaciones Financieras",
                        icon: "eurosign.circle.fill",
                        settings: [
                            ("Pagos Procesados", $notificationSettings.paymentProcessed),
                            ("Pagos Fallidos", $notificationSettings.paymentFailed),
                            ("Reembolsos", $notificationSettings.refundProcessed)
                        ]
                    )

                    // System Notifications
                    notificationSection(
                        title: "Notificaciones del Sistema",
                        icon: "exclamationmark.triangle.fill",
                        settings: [
                            ("Alertas Críticas", $notificationSettings.criticalAlerts),
                            ("Mantenimiento", $notificationSettings.maintenanceAlerts),
                            ("Actualizaciones", $notificationSettings.systemUpdates)
                        ]
                    )

                    saveButton
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func notificationSection(title: String, icon: String, settings: [(String, Binding<Bool>)]) -> some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text(title)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ForEach(settings.indices, id: \.self) { index in
                    NotificationToggleRow(title: settings[index].0, isEnabled: settings[index].1)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            saveSettings()
        } label: {
            Text("Guardar Configuración")
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(ComfortaDesign.Radius.md)
        }
    }

    private func saveSettings() {
        // Save notification settings
        HapticManager.shared.notification(.success)
        AnalyticsService.shared.track(.notificationSettingsUpdated)
        dismiss()
    }
}

struct NotificationSettings {
    // Trip Notifications
    var newTripRequests = true
    var tripCompleted = true
    var tripCancelled = true
    var tripModified = false

    // User Notifications
    var newUserRegistration = true
    var userSuspended = true
    var driverVerified = true

    // Financial Notifications
    var paymentProcessed = false
    var paymentFailed = true
    var refundProcessed = true

    // System Notifications
    var criticalAlerts = true
    var maintenanceAlerts = true
    var systemUpdates = false
}

struct NotificationToggleRow: View {
    let title: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Suspended Users View

struct AdminSuspendedUsersView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var suspendedUsers: [SuspendedUser] = []
    @State private var selectedUser: SuspendedUser?
    @State private var showingUserDetails = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.md) {
                    if suspendedUsers.isEmpty {
                        emptyState
                    } else {
                        ForEach(suspendedUsers) { user in
                            SuspendedUserCard(user: user) {
                                selectedUser = user
                                showingUserDetails = true
                            }
                        }
                    }
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Usuarios Suspendidos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUserDetails) {
                if let user = selectedUser {
                    SuspendedUserDetailView(user: user) { action in
                        handleUserAction(action, for: user)
                    }
                }
            }
            .onAppear {
                loadSuspendedUsers()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: ComfortaDesign.Spacing.lg) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            Text("No hay usuarios suspendidos")
                .font(ComfortaDesign.Typography.title2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Text("Todos los usuarios están en buen estado")
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(ComfortaDesign.Spacing.xl)
    }

    private func loadSuspendedUsers() {
        suspendedUsers = adminService.allUsers
            .filter { !$0.isActive }
            .map { user in
                SuspendedUser(
                    id: user.id,
                    name: user.fullName,
                    email: user.email ?? "",
                    suspendedDate: Date().addingTimeInterval(-86400 * Double.random(in: 1...30)),
                    reason: "Violación de términos de servicio",
                    totalTrips: user.totalTrips,
                    totalSpent: user.totalSpent
                )
            }
    }

    private func handleUserAction(_ action: SuspendedUserAction, for user: SuspendedUser) {
        switch action {
        case .reactivate:
            adminService.reactivateUser(user.id)
            loadSuspendedUsers()
        case .permanentBan:
            // Handle permanent ban
            break
        case .contactUser:
            // Handle contact user
            break
        }
        showingUserDetails = false
    }
}

struct SuspendedUser: Identifiable {
    let id: String
    let name: String
    let email: String
    let suspendedDate: Date
    let reason: String
    let totalTrips: Int
    let totalSpent: Double
}

struct SuspendedUserCard: View {
    let user: SuspendedUser
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ModernCard(style: .surface) {
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    HStack {
                        Circle()
                            .fill(ComfortaDesign.Colors.error.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .foregroundColor(ComfortaDesign.Colors.error)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(ComfortaDesign.Typography.body1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)

                            Text(user.email)
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }

                    Divider().background(ComfortaDesign.Colors.glassBorder)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Razón: \(user.reason)")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)

                        Text("Suspendido: \(DateFormatter.shortDateFormatter.string(from: user.suspendedDate))")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuspendedUserDetailView: View {
    let user: SuspendedUser
    let onAction: (SuspendedUserAction) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    userInfoSection
                    suspensionInfoSection
                    actionsSection
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Detalle de Usuario")
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

    private var userInfoSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Circle()
                    .fill(ComfortaDesign.Colors.error.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(ComfortaDesign.Colors.error)
                    )

                Text(user.name)
                    .font(ComfortaDesign.Typography.title2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text(user.email)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)

                HStack(spacing: ComfortaDesign.Spacing.lg) {
                    VStack {
                        Text("\(user.totalTrips)")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Viajes")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }

                    Rectangle()
                        .fill(ComfortaDesign.Colors.glassBorder)
                        .frame(width: 1, height: 40)

                    VStack {
                        Text(String(format: "€%.0f", user.totalSpent))
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Gastado")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var suspensionInfoSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Información de Suspensión")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                detailRow(title: "Fecha de Suspensión", value: DateFormatter.shortDateFormatter.string(from: user.suspendedDate))
                detailRow(title: "Razón", value: user.reason)
                detailRow(title: "Días Suspendido", value: "\(daysSuspended)")
            }
        }
    }

    private var actionsSection: some View {
        ModernCard(style: .surface) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Acciones")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                Button {
                    onAction(.reactivate)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Reactivar Usuario")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.primaryGreen)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }

                Button {
                    onAction(.contactUser)
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Contactar Usuario")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ComfortaDesign.Colors.info)
                    .cornerRadius(ComfortaDesign.Radius.md)
                }

                Button {
                    onAction(.permanentBan)
                } label: {
                    HStack {
                        Image(systemName: "slash.circle.fill")
                        Text("Banear Permanentemente")
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

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
    }

    private var daysSuspended: Int {
        Calendar.current.dateComponents([.day], from: user.suspendedDate, to: Date()).day ?? 0
    }
}

enum SuspendedUserAction {
    case reactivate
    case permanentBan
    case contactUser
}

// MARK: - Reports Management View

struct AdminReportsView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var selectedPeriod: ReportPeriod = .daily
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var showingExportOptions = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    periodSelectorSection
                    quickStatsSection
                    exportSection
                    recentReportsSection
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Reportes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var periodSelectorSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Período del Reporte")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                HStack(spacing: ComfortaDesign.Spacing.sm) {
                    PeriodButton(period: .daily, selectedPeriod: $selectedPeriod)
                    PeriodButton(period: .weekly, selectedPeriod: $selectedPeriod)
                    PeriodButton(period: .monthly, selectedPeriod: $selectedPeriod)
                    PeriodButton(period: .yearly, selectedPeriod: $selectedPeriod)
                }
            }
        }
    }

    private var quickStatsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Resumen Rápido")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    QuickStatCard(title: "Total Usuarios", value: "\(adminService.stats.totalActiveUsers)", icon: "person.3.fill")
                    QuickStatCard(title: "Viajes", value: "\(adminService.stats.tripsToday)", icon: "car.fill")
                    QuickStatCard(title: "Ingresos", value: String(format: "€%.0f", adminService.stats.totalRevenue), icon: "eurosign.circle.fill")
                    QuickStatCard(title: "Comisión", value: String(format: "€%.0f", adminService.stats.platformCommission), icon: "percent")
                }
            }
        }
    }

    private var exportSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Exportar Datos")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                HStack(spacing: ComfortaDesign.Spacing.sm) {
                    FormatButton(format: .csv, selectedFormat: $selectedFormat)
                    FormatButton(format: .json, selectedFormat: $selectedFormat)
                    FormatButton(format: .pdf, selectedFormat: $selectedFormat)
                }

                Button {
                    exportReport()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Exportar Reporte")
                    }
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(ComfortaDesign.Radius.md)
                }
            }
        }
    }

    private var recentReportsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Reportes Recientes")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ForEach(0..<3) { index in
                    ReportHistoryRow(
                        name: "Reporte \(periodName) - \(formatDate(daysAgo: index))",
                        format: selectedFormat,
                        date: Date().addingTimeInterval(-86400 * Double(index))
                    )
                }
            }
        }
    }

    private func exportReport() {
        if let data = adminService.exportData(format: selectedFormat) {
            // Handle export
            HapticManager.shared.notification(.success)
            AnalyticsService.shared.track(.reportExported, metadata: [
                "format": selectedFormat.rawValue,
                "period": periodName
            ])
        }
    }

    private var periodName: String {
        switch selectedPeriod {
        case .daily: return "Diario"
        case .weekly: return "Semanal"
        case .monthly: return "Mensual"
        case .yearly: return "Anual"
        }
    }

    private func formatDate(daysAgo: Int) -> String {
        let date = Date().addingTimeInterval(-86400 * Double(daysAgo))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct PeriodButton: View {
    let period: ReportPeriod
    @Binding var selectedPeriod: ReportPeriod

    var isSelected: Bool {
        period == selectedPeriod
    }

    var body: some View {
        Button {
            selectedPeriod = period
        } label: {
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(isSelected ? .white : ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ?
                        LinearGradient(
                            colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [ComfortaDesign.Colors.surface, ComfortaDesign.Colors.surface],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .cornerRadius(ComfortaDesign.Radius.sm)
        }
    }

    private var title: String {
        switch period {
        case .daily: return "Diario"
        case .weekly: return "Semanal"
        case .monthly: return "Mensual"
        case .yearly: return "Anual"
        }
    }
}

struct FormatButton: View {
    let format: ExportFormat
    @Binding var selectedFormat: ExportFormat

    var isSelected: Bool {
        format == selectedFormat
    }

    var body: some View {
        Button {
            selectedFormat = format
        } label: {
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(isSelected ? .white : ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ?
                        ComfortaDesign.Colors.primaryGreen :
                        ComfortaDesign.Colors.surface
                )
                .cornerRadius(ComfortaDesign.Radius.sm)
        }
    }

    private var title: String {
        switch format {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            Text(value)
                .font(ComfortaDesign.Typography.title2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .padding(ComfortaDesign.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct ReportHistoryRow: View {
    let name: String
    let format: ExportFormat
    let date: Date

    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text(DateFormatter.shortDateFormatter.string(from: date))
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }

            Spacer()

            Text(formatName)
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(ComfortaDesign.Colors.surface)
                )
        }
        .padding(.vertical, 4)
    }

    private var formatName: String {
        switch format {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        }
    }
}

// MARK: - Security Settings View

struct AdminSecuritySettingsView: View {
    @State private var twoFactorEnabled = false
    @State private var sessionTimeout = 30.0
    @State private var requirePasswordChange = true
    @State private var allowMultipleSessions = false
    @State private var ipWhitelist = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    authenticationSection
                    sessionSection
                    accessControlSection
                    auditLogSection
                    saveButton
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Seguridad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var authenticationSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text("Autenticación")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Autenticación de Dos Factores")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Requerida para acceso administrativo")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $twoFactorEnabled)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cambio de Contraseña Periódico")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Cada 90 días")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $requirePasswordChange)
                }
            }
        }
    }

    private var sessionSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text("Gestión de Sesiones")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tiempo de Espera de Sesión")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    HStack {
                        Slider(value: $sessionTimeout, in: 5...120, step: 5)
                        Text("\(Int(sessionTimeout)) min")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            .frame(width: 60)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Múltiples Sesiones Simultáneas")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Permitir login desde varios dispositivos")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $allowMultipleSessions)
                }
            }
        }
    }

    private var accessControlSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text("Control de Acceso")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lista Blanca de IPs")
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    Text("Ingresa las IPs permitidas separadas por comas")
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    TextField("192.168.1.1, 10.0.0.1", text: $ipWhitelist)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(ComfortaDesign.Typography.body2)
                }
            }
        }
    }

    private var auditLogSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    Text("Registro de Auditoría")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }

                Divider().background(ComfortaDesign.Colors.glassBorder)

                Button {
                    // View audit logs
                } label: {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Ver Registro de Accesos")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }

                Button {
                    // View security events
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                        Text("Ver Eventos de Seguridad")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            saveSettings()
        } label: {
            Text("Guardar Configuración de Seguridad")
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(ComfortaDesign.Radius.md)
        }
    }

    private func saveSettings() {
        HapticManager.shared.notification(.success)
        AnalyticsService.shared.track(.securitySettingsUpdated)
        dismiss()
    }
}

// MARK: - Advanced Reports View

struct AdminAdvancedReportsView: View {
    @StateObject private var adminService = AdminService.shared
    @State private var selectedMetric: AnalyticsMetric = .revenue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    metricSelectorSection
                    chartSection
                    detailedStatsSection
                    trendsSection
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Reportes Avanzados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var metricSelectorSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Seleccionar Métrica")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ComfortaDesign.Spacing.sm) {
                        ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                            MetricChip(metric: metric, isSelected: selectedMetric == metric) {
                                selectedMetric = metric
                            }
                        }
                    }
                }
            }
        }
    }

    private var chartSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text(selectedMetric.title)
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                SimpleLineChart(data: chartData)
                    .frame(height: 250)
            }
        }
    }

    private var detailedStatsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Estadísticas Detalladas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    DetailedStatCard(title: "Promedio", value: averageValue, icon: "chart.bar.fill")
                    DetailedStatCard(title: "Máximo", value: maxValue, icon: "arrow.up.circle.fill")
                    DetailedStatCard(title: "Mínimo", value: minValue, icon: "arrow.down.circle.fill")
                    DetailedStatCard(title: "Total", value: totalValue, icon: "sum")
                }
            }
        }
    }

    private var trendsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Tendencias")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                TrendRow(
                    title: "Crecimiento Semanal",
                    value: "+12.5%",
                    isPositive: true,
                    icon: "arrow.up.right"
                )

                TrendRow(
                    title: "Comparación Mes Anterior",
                    value: "+8.3%",
                    isPositive: true,
                    icon: "arrow.up.right"
                )

                TrendRow(
                    title: "Proyección Mensual",
                    value: String(format: "€%.0f", adminService.stats.monthlyRevenue * 1.15),
                    isPositive: true,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }

    private var chartData: [Double] {
        switch selectedMetric {
        case .revenue:
            return adminService.revenueData.map { $0.revenue }
        case .trips:
            return [100, 120, 95, 140, 160, 150, 170]
        case .users:
            return [50, 60, 58, 75, 80, 85, 90]
        case .conversionRate:
            return [0.65, 0.70, 0.68, 0.75, 0.78, 0.80, 0.82]
        }
    }

    private var averageValue: String {
        let avg = chartData.reduce(0, +) / Double(chartData.count)
        return formatValue(avg)
    }

    private var maxValue: String {
        formatValue(chartData.max() ?? 0)
    }

    private var minValue: String {
        formatValue(chartData.min() ?? 0)
    }

    private var totalValue: String {
        formatValue(chartData.reduce(0, +))
    }

    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .revenue:
            return String(format: "€%.0f", value)
        case .trips, .users:
            return String(format: "%.0f", value)
        case .conversionRate:
            return String(format: "%.1f%%", value * 100)
        }
    }
}

enum AnalyticsMetric: CaseIterable {
    case revenue
    case trips
    case users
    case conversionRate

    var title: String {
        switch self {
        case .revenue: return "Ingresos"
        case .trips: return "Viajes"
        case .users: return "Usuarios"
        case .conversionRate: return "Tasa de Conversión"
        }
    }

    var icon: String {
        switch self {
        case .revenue: return "eurosign.circle.fill"
        case .trips: return "car.fill"
        case .users: return "person.3.fill"
        case .conversionRate: return "percent"
        }
    }
}

struct MetricChip: View {
    let metric: AnalyticsMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: metric.icon)
                Text(metric.title)
            }
            .font(ComfortaDesign.Typography.caption1)
            .foregroundColor(isSelected ? .white : ComfortaDesign.Colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                    LinearGradient(
                        colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [ComfortaDesign.Colors.surface, ComfortaDesign.Colors.surface],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(ComfortaDesign.Radius.sm)
        }
    }
}

struct DetailedStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)

            Text(value)
                .font(ComfortaDesign.Typography.title3)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Text(title)
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .padding(ComfortaDesign.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.sm)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let isPositive: Bool
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isPositive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)

            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(isPositive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Input Components

struct PriceInputRow: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let onChange: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Spacer()

            TextField("", value: $value, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
                .onChangeCompat(of: value) { onChange() }

            Text(unit)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

struct MultiplierInputRow: View {
    let title: String
    @Binding var multiplier: Double

    var body: some View {
        HStack {
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Spacer()

            TextField("", value: $multiplier, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .multilineTextAlignment(.trailing)

            Text("x")
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .frame(width: 20)
        }
    }
}

// MARK: - AdminUserDetailsView

struct AdminUserDetailsView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    userHeaderSection
                    userStatsSection
                    userActionsSection
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Detalle de Usuario")
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

    private var userHeaderSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Circle()
                    .fill(ComfortaDesign.Colors.primaryGreen)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(user.firstName.prefix(1)))
                            .font(ComfortaDesign.Typography.title1)
                            .foregroundColor(.white)
                    )

                Text(user.fullName)
                    .font(ComfortaDesign.Typography.title2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text(user.email ?? "")
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)

                StatusPill(
                    text: user.isActive ? "Activo" : "Suspendido",
                    color: user.isActive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error
                )
            }
        }
    }

    private var userStatsSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Estadísticas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    QuickStatCard(title: "Viajes", value: "\(user.totalTrips)", icon: "car.fill")
                    QuickStatCard(title: "Gastado", value: String(format: "€%.0f", user.totalSpent), icon: "eurosign.circle.fill")
                    QuickStatCard(title: "Puntos", value: "\(user.loyaltyPoints)", icon: "star.fill")
                    QuickStatCard(title: "Calificación", value: String(format: "%.1f", user.rating), icon: "star.circle.fill")
                }
            }
        }
    }

    private var userActionsSection: some View {
        ModernCard(style: .surface) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Acciones")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                if user.isActive {
                    Button {
                        AdminService.shared.suspendUser(user.id, reason: "Suspendido desde panel de administración")
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                            Text("Suspender Usuario")
                        }
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ComfortaDesign.Colors.error)
                        .cornerRadius(ComfortaDesign.Radius.md)
                    }
                } else {
                    Button {
                        AdminService.shared.reactivateUser(user.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("Reactivar Usuario")
                        }
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ComfortaDesign.Colors.primaryGreen)
                        .cornerRadius(ComfortaDesign.Radius.md)
                    }
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func onChangeCompat<Value: Equatable>(of value: Value, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, _ in
                action()
            }
        } else {
            self.onChange(of: value) { _ in
                action()
            }
        }
    }
}

private extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

extension ReportPeriod: Equatable {}
extension ExportFormat: RawRepresentable {
    typealias RawValue = String

    init?(rawValue: String) {
        switch rawValue {
        case "csv": self = .csv
        case "json": self = .json
        case "pdf": self = .pdf
        default: return nil
        }
    }

    var rawValue: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
}
