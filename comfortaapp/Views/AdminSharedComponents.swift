import SwiftUI

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String
    var progress: Double? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if let progress = progress {
                    CircularProgressView(progress: progress)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }

                Text(message)
                    .foregroundColor(.white)
                    .font(ComfortaDesign.Typography.headline)
                    .multilineTextAlignment(.center)

                if let progress = progress {
                    Text("\(Int(progress * 100))%")
                        .foregroundColor(.white.opacity(0.8))
                        .font(ComfortaDesign.Typography.body2)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .padding(40)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 8)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ComfortaDesign.Colors.primaryGreen,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
}

// MARK: - Validated Price Input Row

struct ValidatedPriceInputRow: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>
    let fieldKey: String
    let validationErrors: [String: String]
    let onChange: () -> Void

    var isValid: Bool {
        validationErrors[fieldKey] == nil
    }

    var errorMessage: String? {
        validationErrors[fieldKey]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Spacer()

                TextField("", value: $value, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(isValid ? ComfortaDesign.Colors.textPrimary : ComfortaDesign.Colors.error)
                    .onChangeCompat(of: value) { onChange() }

                Text(unit)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .frame(width: 40, alignment: .leading)
            }

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(ComfortaDesign.Colors.error)

                    Text(error)
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.error)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }
}

// MARK: - Confirmation Dialog

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmButtonText: String
    let confirmationKeyword: String?
    let isDestructive: Bool
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    @State private var confirmationText = ""
    @FocusState private var isTextFieldFocused: Bool

    var isConfirmEnabled: Bool {
        if let keyword = confirmationKeyword {
            return confirmationText.uppercased() == keyword.uppercased()
        }
        return true
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: isDestructive ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(isDestructive ? ComfortaDesign.Colors.error : ComfortaDesign.Colors.warning)

                    Text(title)
                        .font(ComfortaDesign.Typography.title2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Confirmation input if required
                if let keyword = confirmationKeyword {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Escribe '\(keyword)' para confirmar")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)

                        TextField("", text: $confirmationText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .focused($isTextFieldFocused)
                            .font(ComfortaDesign.Typography.body1)
                    }
                }

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        isPresented = false
                        confirmationText = ""
                    } label: {
                        Text("Cancelar")
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(ComfortaDesign.Colors.surface)
                            .cornerRadius(ComfortaDesign.Radius.md)
                    }

                    Button {
                        if isConfirmEnabled {
                            onConfirm()
                            isPresented = false
                            confirmationText = ""
                        }
                    } label: {
                        Text(confirmButtonText)
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                isConfirmEnabled ?
                                    (isDestructive ? ComfortaDesign.Colors.error : ComfortaDesign.Colors.primaryGreen) :
                                    ComfortaDesign.Colors.textSecondary
                            )
                            .cornerRadius(ComfortaDesign.Radius.md)
                    }
                    .disabled(!isConfirmEnabled)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ComfortaDesign.Colors.background)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(40)
        }
        .onAppear {
            isTextFieldFocused = confirmationKeyword != nil
        }
    }
}

// MARK: - Pricing Comparison View

struct PricingComparisonView: View {
    let currentPricing: PricingStructure
    let newPricing: PricingStructure
    let impact: PricingImpact?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    // Impact Card
                    if let impact = impact {
                        impactCard(impact)
                    }

                    // Comparisons
                    comparisonSection

                    // Vehicle Multipliers
                    vehicleMultipliersComparison
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Comparación de Precios")
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

    private func impactCard(_ impact: PricingImpact) -> some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Impacto Estimado")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text("(Viaje promedio de 10 km)")
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                HStack(spacing: ComfortaDesign.Spacing.xl) {
                    VStack(spacing: 4) {
                        Text("Antes")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Text("€\(String(format: "%.2f", impact.oldPrice))")
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    VStack(spacing: 4) {
                        Text("Después")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Text("€\(String(format: "%.2f", impact.newPrice))")
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(impact.impactColor)
                    }
                }

                Text(impact.impactDescription)
                    .font(ComfortaDesign.Typography.headline)
                    .foregroundColor(impact.impactColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(impact.impactColor.opacity(0.15))
                    )
            }
        }
    }

    private var comparisonSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Cambios en Tarifas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ComparisonRow(
                    title: "Tarifa Base",
                    before: "€\(String(format: "%.2f", currentPricing.baseFare))",
                    after: "€\(String(format: "%.2f", newPricing.baseFare))",
                    hasChanged: currentPricing.baseFare != newPricing.baseFare
                )

                ComparisonRow(
                    title: "Por Kilómetro",
                    before: "€\(String(format: "%.2f", currentPricing.perKilometerRate))/km",
                    after: "€\(String(format: "%.2f", newPricing.perKilometerRate))/km",
                    hasChanged: currentPricing.perKilometerRate != newPricing.perKilometerRate
                )

                ComparisonRow(
                    title: "Por Minuto",
                    before: "€\(String(format: "%.2f", currentPricing.perMinuteRate))/min",
                    after: "€\(String(format: "%.2f", newPricing.perMinuteRate))/min",
                    hasChanged: currentPricing.perMinuteRate != newPricing.perMinuteRate
                )

                ComparisonRow(
                    title: "Tarifa Mínima",
                    before: "€\(String(format: "%.2f", currentPricing.minimumFare))",
                    after: "€\(String(format: "%.2f", newPricing.minimumFare))",
                    hasChanged: currentPricing.minimumFare != newPricing.minimumFare
                )

                ComparisonRow(
                    title: "Tarifa Mínima Viajes Largos",
                    before: "€\(String(format: "%.2f", currentPricing.minimumFareForLongTrips))",
                    after: "€\(String(format: "%.2f", newPricing.minimumFareForLongTrips))",
                    hasChanged: currentPricing.minimumFareForLongTrips != newPricing.minimumFareForLongTrips
                )

                ComparisonRow(
                    title: "Recargo Aeropuerto",
                    before: "€\(String(format: "%.2f", currentPricing.airportSurcharge))",
                    after: "€\(String(format: "%.2f", newPricing.airportSurcharge))",
                    hasChanged: currentPricing.airportSurcharge != newPricing.airportSurcharge
                )

                ComparisonRow(
                    title: "Comisión",
                    before: "\(String(format: "%.1f", currentPricing.commissionRate))%",
                    after: "\(String(format: "%.1f", newPricing.commissionRate))%",
                    hasChanged: currentPricing.commissionRate != newPricing.commissionRate
                )
            }
        }
    }

    private var vehicleMultipliersComparison: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Multiplicadores de Vehículo")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Divider().background(ComfortaDesign.Colors.glassBorder)

                ForEach(Array(currentPricing.vehicleMultipliers.keys.sorted()), id: \.self) { vehicle in
                    let oldValue = currentPricing.vehicleMultipliers[vehicle] ?? 1.0
                    let newValue = newPricing.vehicleMultipliers[vehicle] ?? 1.0

                    ComparisonRow(
                        title: vehicleTypeName(vehicle),
                        before: "\(String(format: "%.1fx", oldValue))",
                        after: "\(String(format: "%.1fx", newValue))",
                        hasChanged: oldValue != newValue
                    )
                }
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

struct ComparisonRow: View {
    let title: String
    let before: String
    let after: String
    let hasChanged: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)

            Spacer()

            if hasChanged {
                HStack(spacing: 8) {
                    Text(before)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .strikethrough()

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)

                    Text(after)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        .bold()
                }
            } else {
                Text(before)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Audit Log View

struct AuditLogView: View {
    @State private var changes: [ConfigurationChange] = []
    @State private var selectedSection: String = "Todos"
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    let sections = ["Todos", "Precios", "Usuarios", "Reportes", "Seguridad", "Notificaciones"]

    var filteredChanges: [ConfigurationChange] {
        var filtered = changes

        if selectedSection != "Todos" {
            filtered = filtered.filter { $0.section == selectedSection }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { change in
                change.field.localizedCaseInsensitiveContains(searchText) ||
                change.oldValue.localizedCaseInsensitiveContains(searchText) ||
                change.newValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    TextField("Buscar cambios...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(ComfortaDesign.Colors.surface)
                .cornerRadius(ComfortaDesign.Radius.sm)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Section filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sections, id: \.self) { section in
                            AdminFilterChip(
                                title: section,
                                isSelected: selectedSection == section
                            ) {
                                selectedSection = section
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // Changes list
                if filteredChanges.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredChanges) { change in
                                AuditLogCard(change: change)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Historial de Cambios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            exportAuditLog()
                        } label: {
                            Label("Exportar CSV", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            clearOldLogs()
                        } label: {
                            Label("Limpiar logs antiguos", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadChanges()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(ComfortaDesign.Colors.textSecondary)

            Text("No hay cambios registrados")
                .font(ComfortaDesign.Typography.title3)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)

            Text("Los cambios de configuración aparecerán aquí")
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadChanges() {
        Task {
            changes = await AuditLogService.shared.getAllChanges()
        }
    }

    private func exportAuditLog() {
        Task {
            if await AuditLogService.shared.exportAuditLog(format: .csv) != nil {
                // Save or share the file
                print("✅ Audit log exported")
            }
        }
    }

    private func clearOldLogs() {
        Task {
            await AuditLogService.shared.clearOldChanges(olderThan: 90)
            loadChanges()
        }
    }
}

struct AuditLogCard: View {
    let change: ConfigurationChange

    var body: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(change.section)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(ComfortaDesign.Colors.primaryGreen)
                        )

                    Spacer()

                    Text(change.timestamp, style: .relative)
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }

                Text(change.field)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .bold()

                HStack {
                    Text(change.oldValue)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .strikethrough()

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    Text(change.newValue)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }

                Text("Por: \(change.adminName)")
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
        }
    }
}

struct AdminFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(isSelected ? .white : ComfortaDesign.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.surface)
                )
        }
    }
}

// MARK: - Compatibility Extension

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
