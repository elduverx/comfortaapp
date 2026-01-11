import SwiftUI

// MARK: - Stat Card

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let trend: TrendType?
    let style: AnalyticsCardStyle

    @State private var isAnimating = false

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        trend: TrendType? = nil,
        style: AnalyticsCardStyle = .primary
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.style = style
    }

    var body: some View {
        ModernCard(style: .glass, animation: false) {
            HStack(spacing: ComfortaDesign.Spacing.md) {
                // Icon
                iconView

                // Content
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
                    Text(title)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)

                    Text(value)
                        .font(ComfortaDesign.Typography.title2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                }

                Spacer()

                // Trend Indicator
                if let trend = trend {
                    trendView(trend)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(style.iconColor)
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(style.iconColor.opacity(0.15))
            )
    }

    @ViewBuilder
    private func trendView(_ trend: TrendType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .bold))

            Text(trend.valueText)
                .font(ComfortaDesign.Typography.caption2)
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.15))
        )
    }
}

enum AnalyticsCardStyle {
    case primary
    case success
    case warning
    case info

    var iconColor: Color {
        switch self {
        case .primary:
            return ComfortaDesign.Colors.primaryGreen
        case .success:
            return ComfortaDesign.Colors.success
        case .warning:
            return ComfortaDesign.Colors.warning
        case .info:
            return ComfortaDesign.Colors.accent
        }
    }
}

enum TrendType {
    case up(Double)
    case down(Double)
    case neutral

    var icon: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .neutral:
            return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up:
            return ComfortaDesign.Colors.success
        case .down:
            return ComfortaDesign.Colors.error
        case .neutral:
            return ComfortaDesign.Colors.textTertiary
        }
    }

    var valueText: String {
        switch self {
        case .up(let value):
            return "+\(String(format: "%.1f", value))%"
        case .down(let value):
            return "-\(String(format: "%.1f", value))%"
        case .neutral:
            return "0%"
        }
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let stats: [StatData]
    let columns: Int

    init(stats: [StatData], columns: Int = 2) {
        self.stats = stats
        self.columns = columns
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: ComfortaDesign.Spacing.md), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: ComfortaDesign.Spacing.md) {
            ForEach(stats) { stat in
                AnalyticsCard(
                    title: stat.title,
                    value: stat.value,
                    subtitle: stat.subtitle,
                    icon: stat.icon,
                    trend: stat.trend,
                    style: stat.style
                )
            }
        }
    }
}

struct StatData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let trend: TrendType?
    let style: AnalyticsCardStyle

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        trend: TrendType? = nil,
        style: AnalyticsCardStyle = .primary
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.style = style
    }
}

// MARK: - Horizontal Stat Card (Compact)

struct CompactAnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)

                Text(value)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(ComfortaDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    ScrollView {
        VStack(spacing: ComfortaDesign.Spacing.lg) {
            AnalyticsCard(
                title: "Total Viajes",
                value: "247",
                subtitle: "Este mes",
                icon: "car.circle.fill",
                trend: .up(12.5),
                style: .primary
            )

            AnalyticsCard(
                title: "Ingresos",
                value: "€15,420",
                subtitle: "Últimos 30 días",
                icon: "eurosign.circle.fill",
                trend: .up(8.3),
                style: .success
            )

            AnalyticsCard(
                title: "Conductores Activos",
                value: "42",
                subtitle: "Disponibles ahora",
                icon: "person.3.fill",
                trend: .down(3.2),
                style: .warning
            )

            AnalyticsCard(
                title: "Satisfacción",
                value: "4.8",
                subtitle: "Promedio de calificación",
                icon: "star.fill",
                trend: .up(2.1),
                style: .info
            )
        }
        .padding()
    }
    .background(ComfortaDesign.Colors.background)
}

#Preview("Stats Grid") {
    ScrollView {
        StatsGrid(
            stats: [
                StatData(
                    title: "Viajes Hoy",
                    value: "28",
                    icon: "calendar",
                    trend: .up(5.2),
                    style: .primary
                ),
                StatData(
                    title: "Usuarios Nuevos",
                    value: "147",
                    icon: "person.badge.plus",
                    trend: .up(15.3),
                    style: .success
                ),
                StatData(
                    title: "Cancelaciones",
                    value: "3",
                    icon: "xmark.circle",
                    trend: .down(2.1),
                    style: .warning
                ),
                StatData(
                    title: "Rating Promedio",
                    value: "4.9",
                    icon: "star.fill",
                    trend: .up(0.2),
                    style: .info
                )
            ]
        )
        .padding()
    }
    .background(ComfortaDesign.Colors.background)
}

#Preview("Compact Stats") {
    VStack(spacing: ComfortaDesign.Spacing.sm) {
        CompactAnalyticsCard(
            title: "Distancia",
            value: "45.2 km",
            icon: "location.fill",
            color: ComfortaDesign.Colors.primaryGreen
        )

        CompactAnalyticsCard(
            title: "Duración",
            value: "38 min",
            icon: "clock.fill",
            color: ComfortaDesign.Colors.accent
        )

        CompactAnalyticsCard(
            title: "Precio",
            value: "€52.40",
            icon: "eurosign.circle.fill",
            color: ComfortaDesign.Colors.success
        )
    }
    .padding()
    .background(ComfortaDesign.Colors.background)
}
