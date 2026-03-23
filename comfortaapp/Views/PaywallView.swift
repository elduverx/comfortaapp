import SwiftUI

struct PaywallView: View {
    let fare: String
    let distance: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var selectedPaymentOption: PaymentOption = .card
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ComfortaDesign.Colors.background,
                    ComfortaDesign.Colors.surface,
                    ComfortaDesign.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                Capsule()
                    .fill(ComfortaDesign.Colors.glassBorder)
                    .frame(width: 56, height: 6)
                    .opacity(0.5)
                    .padding(.top, ComfortaDesign.Spacing.md)
                
                ModernCard(style: .glass) {
                    VStack(spacing: ComfortaDesign.Spacing.md) {
                        VStack(spacing: ComfortaDesign.Spacing.xs) {
                            Text("Pagar viaje")
                                .font(ComfortaDesign.Typography.title2)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            Text("Confirma tu recorrido y autoriza el cobro")
                                .font(ComfortaDesign.Typography.body2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(distance.isEmpty ? "Distancia" : distance)
                                    .font(ComfortaDesign.Typography.title3)
                                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                                Text("Trayecto estimado")
                                    .font(ComfortaDesign.Typography.caption1)
                                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(fare)
                                    .font(ComfortaDesign.Typography.title1)
                                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                                Text("Precio real del viaje")
                                    .font(ComfortaDesign.Typography.caption1)
                                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            }
                        }
                        
                        Divider().background(ComfortaDesign.Colors.glassBorder)
                        
                        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
                            Text("Incluye")
                                .font(ComfortaDesign.Typography.body1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            Text("Servicio Comforta, ruta optimizada y soporte premium en ruta.")
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                            Text("Metodo de pago")
                                .font(ComfortaDesign.Typography.body1)
                                .foregroundColor(ComfortaDesign.Colors.textPrimary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: ComfortaDesign.Spacing.sm) {
                                ForEach(PaymentOption.allCases) { option in
                                    PaymentOptionButton(
                                        option: option,
                                        isSelected: selectedPaymentOption == option
                                    ) {
                                        selectedPaymentOption = option
                                    }
                                }
                            }
                        }
                        
                        LiquidButton("Confirmar y pagar", icon: "checkmark.seal.fill", style: .primary, size: .large) {
                            onConfirm()
                        }
                        
                        Button(action: onCancel) {
                            Text("Volver")
                                .font(ComfortaDesign.Typography.body2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                                .padding(.vertical, ComfortaDesign.Spacing.sm)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, ComfortaDesign.Spacing.lg)
                
                Spacer()
            }
        }
        .onAppear {
            AnalyticsService.shared.track(.viewPaywall)
        }
    }
}

private enum PaymentOption: String, CaseIterable, Identifiable {
    case card
    case bizum
    case cash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card:
            return "Tarjeta"
        case .bizum:
            return "Bizum"
        case .cash:
            return "Efectivo"
        }
    }

    var icon: String {
        switch self {
        case .card:
            return "creditcard.fill"
        case .bizum:
            return "wave.3.right.circle.fill"
        case .cash:
            return "banknote.fill"
        }
    }
}

private struct PaymentOptionButton: View {
    let option: PaymentOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.textSecondary)
                Text(option.title)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? ComfortaDesign.Colors.lightGreen.opacity(0.35) : ComfortaDesign.Colors.surfaceSecondary)
            .cornerRadius(ComfortaDesign.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                    .stroke(isSelected ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
