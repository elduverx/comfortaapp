import SwiftUI

struct APITripDetailsView: View {
    let trip: APITrip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ComfortaDesign.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                        statusSection
                        routeSection
                        detailsSection
                        paymentSection
                    }
                    .padding(.horizontal, ComfortaDesign.Spacing.lg)
                    .padding(.top, ComfortaDesign.Spacing.md)
                }
            }
            .navigationTitle("Detalles del Viaje")
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
            HStack {
                Circle()
                    .fill(trip.statusColor)
                    .frame(width: 12, height: 12)

                Text(trip.statusDisplayName)
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(trip.statusColor)

                Spacer()

                Text(formatDate(trip.createdAtDate))
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
        }
    }

    private var routeSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Ruta")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                    RouteRow(
                        icon: "location.circle.fill",
                        iconColor: ComfortaDesign.Colors.primaryGreen,
                        text: trip.lugarRecogida ?? "-",
                        isDestination: false
                    )

                    RouteRow(
                        icon: "flag.checkered",
                        iconColor: ComfortaDesign.Colors.error,
                        text: trip.destino,
                        isDestination: true
                    )
                }
            }
        }
    }

    private var detailsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Información del Viaje")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    detailItem(
                        icon: "eurosign.circle.fill",
                        title: "Precio",
                        value: trip.formattedPrice,
                        color: ComfortaDesign.Colors.primaryGreen
                    )

                    detailItem(
                        icon: "ruler",
                        title: "Distancia",
                        value: trip.formattedDistance,
                        color: ComfortaDesign.Colors.accent
                    )

                    detailItem(
                        icon: "clock.fill",
                        title: "Duración",
                        value: trip.formattedDuration,
                        color: ComfortaDesign.Colors.warning
                    )

                    detailItem(
                        icon: "calendar",
                        title: "Inicio",
                        value: formatDate(trip.fechaInicio.toDate()),
                        color: ComfortaDesign.Colors.textSecondary
                    )
                }
            }
        }
    }

    private var paymentSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Pago")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.paymentMethod ?? "Pendiente")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)

                        Text(trip.pagado ? "Pagado" : "Sin pagar")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(trip.pagado ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.warning)
                    }

                    Spacer()

                    Text(trip.numeroFactura ?? "-")
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
        }
    }

    private func detailItem(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)

                Text(value)
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
