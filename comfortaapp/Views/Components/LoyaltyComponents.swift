import SwiftUI

struct BenefitTile: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                .padding(10)
                .background(Circle().fill(ComfortaDesign.Colors.surfaceSecondary))

            Text(title)
                .font(ComfortaDesign.Typography.body1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
            Text(subtitle)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .padding(ComfortaDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(ComfortaDesign.Colors.surfaceSecondary)
        )
    }
}

struct AchievementBadge: View {
    let achievement: ProfileAchievement

    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.xs) {
            Circle()
                .fill(achievement.color.opacity(0.2))
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(achievement.color)
                )
            Text(achievement.title)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
            Text(achievement.subtitle)
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .frame(width: 120)
    }
}

struct ProfileAchievement: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}
