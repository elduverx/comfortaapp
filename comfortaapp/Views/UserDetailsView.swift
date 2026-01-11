import SwiftUI

struct UserDetailsView: View {
    let user: User
    @StateObject private var adminService = AdminService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    @State private var confirmationAction: (() -> Void)?
    @State private var confirmationTitle = ""
    @State private var confirmationMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.lg) {
                    // User Profile Section
                    userProfileSection
                    
                    // Stats Section
                    userStatsSection
                    
                    // Trip History Section
                    tripHistorySection
                    
                    // Payment History Section
                    paymentHistorySection
                    
                    // Actions Section
                    actionsSection
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .navigationTitle("Detalles de Usuario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .alert(confirmationTitle, isPresented: $showingConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Confirmar", role: .destructive) {
                confirmationAction?()
            }
        } message: {
            Text(confirmationMessage)
        }
    }
    
    private var userProfileSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    // Profile Picture Placeholder
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(user.firstName.prefix(1)))
                                .font(ComfortaDesign.Typography.title1)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName)
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        if let email = user.email {
                            Text(email)
                                .font(ComfortaDesign.Typography.body2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        HStack {
                            Text(user.userType.displayName)
                                .font(ComfortaDesign.Typography.caption1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.2))
                                )
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            
                            Circle()
                                .fill(user.isActive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
                                .frame(width: 8, height: 8)
                            
                            Text(user.isActive ? "Activo" : "Suspendido")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(user.isActive ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.error)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                // User Information Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    InfoItem(title: "Miembro desde", value: DateFormatter.memberSinceFormatter.string(from: user.dateCreated))
                    InfoItem(title: "Último acceso", value: DateFormatter.lastLoginFormatter.string(from: user.lastLoginDate))
                    InfoItem(title: "Teléfono", value: user.phoneNumber ?? "No proporcionado")
                    InfoItem(title: "Calificación", value: String(format: "%.1f ⭐", user.rating))
                }
            }
        }
    }
    
    private var userStatsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Estadísticas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    StatCard(title: "Total de Viajes", value: "\(user.totalTrips)", icon: "car.fill")
                    StatCard(title: "Total Gastado", value: String(format: "€%.2f", user.totalSpent), icon: "eurosign.circle.fill")
                    StatCard(title: "Puntos de Fidelidad", value: "\(user.loyaltyPoints)", icon: "star.circle.fill")
                    StatCard(title: "Método de Pago", value: user.preferredPaymentMethod.displayName, icon: user.preferredPaymentMethod.iconName)
                }
            }
        }
    }
    
    private var tripHistorySection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Text("Historial de Viajes")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("Ver Todo") {
                        // Navigate to full trip history
                    }
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
                
                // Recent trips (placeholder)
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Viaje #\(index + 1)")
                                    .font(ComfortaDesign.Typography.caption1)
                                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                                
                                Text("Hace \(index + 1) días")
                                    .font(ComfortaDesign.Typography.caption2)
                                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("€\(Double.random(in: 15...45), specifier: "%.2f")")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        }
                    }
                }
            }
        }
    }
    
    private var paymentHistorySection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Text("Historial de Pagos")
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("Ver Todo") {
                        // Navigate to full payment history
                    }
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
                
                // Recent payments (placeholder)
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Image(systemName: user.preferredPaymentMethod.iconName)
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pago #\(index + 1)")
                                    .font(ComfortaDesign.Typography.caption1)
                                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                                
                                Text("Hace \(index + 1) días")
                                    .font(ComfortaDesign.Typography.caption2)
                                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("€\(Double.random(in: 15...45), specifier: "%.2f")")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        }
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Acciones de Administrador")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    if user.isActive {
                        ActionButton(
                            title: "Suspender Usuario",
                            icon: "person.crop.circle.badge.xmark",
                            style: .destructive
                        ) {
                            confirmationTitle = "Suspender Usuario"
                            confirmationMessage = "¿Estás seguro de que quieres suspender a \(user.fullName)?"
                            confirmationAction = {
                                adminService.suspendUser(user.id, reason: "Suspended by admin")
                                dismiss()
                            }
                            showingConfirmation = true
                        }
                    } else {
                        ActionButton(
                            title: "Reactivar Usuario",
                            icon: "person.crop.circle.badge.checkmark",
                            style: .primary
                        ) {
                            confirmationTitle = "Reactivar Usuario"
                            confirmationMessage = "¿Estás seguro de que quieres reactivar a \(user.fullName)?"
                            confirmationAction = {
                                adminService.reactivateUser(user.id)
                                dismiss()
                            }
                            showingConfirmation = true
                        }
                    }
                    
                    ActionButton(
                        title: "Enviar Mensaje",
                        icon: "message.fill",
                        style: .secondary
                    ) {
                        // Implement messaging functionality
                    }
                    
                    ActionButton(
                        title: "Ver Reportes",
                        icon: "exclamationmark.triangle.fill",
                        style: .secondary
                    ) {
                        // Navigate to user reports
                    }
                    
                    ActionButton(
                        title: "Historial Completo",
                        icon: "doc.text.fill",
                        style: .secondary
                    ) {
                        // Navigate to complete user history
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
            
            Text(value)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                Spacer()
            }
            
            Text(value)
                .font(ComfortaDesign.Typography.title3)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ComfortaDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.sm)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let style: ActionButtonStyle
    let action: () -> Void
    
    enum ActionButtonStyle {
        case primary, secondary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return ComfortaDesign.Colors.primaryGreen
            case .secondary:
                return ComfortaDesign.Colors.surfaceSecondary
            case .destructive:
                return ComfortaDesign.Colors.error
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .destructive:
                return .white
            case .secondary:
                return ComfortaDesign.Colors.textPrimary
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(ComfortaDesign.Typography.body2)
            .foregroundColor(style.textColor)
            .padding(ComfortaDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .fill(style.backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - DateFormatter Extensions

private extension DateFormatter {
    static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let lastLoginFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    UserDetailsView(
        user: User(
            id: "123",
            firstName: "María",
            lastName: "García",
            email: "maria@email.com"
        )
    )
}
