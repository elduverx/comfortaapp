import SwiftUI

// MARK: - Error View

struct ErrorView: View {
    let title: String
    let message: String
    let icon: String
    let retryAction: (() -> Void)?

    init(
        title: String = "Algo salió mal",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    var body: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                // Error Icon
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(ComfortaDesign.Colors.error)

                // Error Text
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    Text(title)
                        .font(ComfortaDesign.Typography.title3)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Retry Button
                if let retryAction = retryAction {
                    LiquidButton(
                        "Intentar de nuevo",
                        icon: "arrow.clockwise",
                        style: .primary,
                        size: .medium,
                        action: retryAction
                    )
                }
            }
            .padding(ComfortaDesign.Spacing.lg)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        icon: String = "tray.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.xl) {
            Spacer()

            VStack(spacing: ComfortaDesign.Spacing.lg) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(ComfortaDesign.Colors.textTertiary)

                // Text
                VStack(spacing: ComfortaDesign.Spacing.sm) {
                    Text(title)
                        .font(ComfortaDesign.Typography.title2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    Text(message)
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ComfortaDesign.Spacing.xl)
                }

                // Action Button
                if let actionTitle = actionTitle, let action = action {
                    LiquidButton(
                        actionTitle,
                        icon: "plus.circle.fill",
                        style: .primary,
                        size: .medium,
                        action: action
                    )
                    .padding(.top, ComfortaDesign.Spacing.md)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    let retryAction: () -> Void

    var body: some View {
        ErrorView(
            title: "Sin conexión",
            message: "No pudimos conectar con el servidor. Verifica tu conexión a internet e intenta de nuevo.",
            icon: "wifi.slash",
            retryAction: retryAction
        )
    }
}

// MARK: - Preview

#Preview("Error View") {
    ErrorView(
        message: "No pudimos procesar tu solicitud. Por favor intenta de nuevo.",
        retryAction: {
            print("Retry tapped")
        }
    )
    .padding()
    .background(ComfortaDesign.Colors.background)
}

#Preview("Empty State") {
    EmptyStateView(
        title: "No hay viajes",
        message: "Aún no has realizado ningún viaje. ¡Reserva tu primer viaje ahora!",
        icon: "car.circle",
        actionTitle: "Reservar viaje",
        action: {
            print("Action tapped")
        }
    )
    .background(ComfortaDesign.Colors.background)
}

#Preview("Network Error") {
    NetworkErrorView(retryAction: {
        print("Retry network")
    })
    .padding()
    .background(ComfortaDesign.Colors.background)
}
