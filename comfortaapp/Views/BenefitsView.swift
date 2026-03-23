import SwiftUI

struct BenefitsView: View {
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                loyaltyStatusSection
                rewardsPerksSection
                achievementsSection
                referralRewardsSection
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
            .padding(.top, ComfortaDesign.Spacing.sm)
        }
        .onAppear {
            AnalyticsService.shared.track(.viewHome)
        }
    }

    // MARK: - Sections

    private var loyaltyStatusSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Programa Comforta Rewards")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Nivel actual: \(loyaltyTier)")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    StatusPill(text: "\(loyaltyPoints) pts", color: ComfortaDesign.Colors.primaryGreen)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: loyaltyProgress)
                        .tint(ComfortaDesign.Colors.primaryGreen)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    Text("\(Int(loyaltyProgress * 1000))/1000 para subir de nivel")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
        }
    }

    private var rewardsPerksSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Beneficios Disponibles")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    BenefitTile(icon: "sparkles", title: "10% OFF", subtitle: "Viajes premium")
                    BenefitTile(icon: "cup.and.saucer.fill", title: "Lounge", subtitle: "Acceso Comforta Club")
                    BenefitTile(icon: "creditcard", title: "+150 pts", subtitle: "Cada 5 viajes")
                    BenefitTile(icon: "gift.fill", title: "Invita y gana", subtitle: "€5 por amigo")
                }
            }
        }
    }

    private var achievementsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Logros desbloqueados")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ComfortaDesign.Spacing.md) {
                        ForEach(profileAchievements) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                }
            }
        }
    }

    private var referralRewardsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comparte Comforta")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Obtén créditos por cada amigo que reserve un viaje")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    StatusPill(text: "Código: CF-\(userInitials)", color: ComfortaDesign.Colors.accent)
                }

                Button(action: {}) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir enlace")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Computed Properties

    private var userInitials: String {
        guard let user = userManager.currentUser else { return "U" }
        let firstName = user.firstName.prefix(1)
        let lastName = user.lastName.prefix(1)
        return "\(firstName)\(lastName)".uppercased()
    }

    private var loyaltyPoints: Int {
        userManager.currentUser?.loyaltyPoints ?? 0
    }

    private var loyaltyTier: String {
        switch loyaltyPoints {
        case 0..<300: return "Classic"
        case 300..<700: return "Gold"
        default: return "Elite"
        }
    }

    private var loyaltyProgress: Double {
        min(Double(loyaltyPoints % 1000) / 1000.0, 1.0)
    }

    private var profileAchievements: [ProfileAchievement] {
        [
            ProfileAchievement(title: "Explorador", subtitle: "10 ciudades", icon: "globe.europe.africa.fill", color: ComfortaDesign.Colors.accent),
            ProfileAchievement(title: "Noches Premium", subtitle: "20 viajes nocturnos", icon: "moon.stars.fill", color: ComfortaDesign.Colors.warning),
            ProfileAchievement(title: "Eco Lover", subtitle: "5 viajes eléctricos", icon: "leaf.fill", color: ComfortaDesign.Colors.primaryGreen)
        ]
    }
}

#Preview {
    BenefitsView()
        .environmentObject(UserManager.shared)
}
