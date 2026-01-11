import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingSettings = false
    @State private var showingSupport = false
    @State private var showingPaymentMethods = false
    @State private var isViewReady = false
    @State private var selectedProfileTab = 0

    var body: some View {
        TabView(selection: $selectedProfileTab) {
            overviewTab
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(0)

            benefitsTab
                .tabItem {
                    Label("Beneficios", systemImage: "star.fill")
                }
                .tag(1)

            supportTab
                .tabItem {
                    Label("Soporte", systemImage: "questionmark.circle.fill")
                }
                .tag(2)
        }
        .accentColor(ComfortaDesign.Colors.primaryGreen)
        .onAppear {
            AnalyticsService.shared.track(.viewHome)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSupport) {
            SupportView()
        }
        .sheet(isPresented: $showingPaymentMethods) {
            PaymentMethodsView()
        }
    }

    private func tabContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            ZStack {
                ComfortaDesign.Colors.background.ignoresSafeArea()
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                profileHeaderSection
                quickStatsSection
                menuSection
                appInfoSection
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
            .padding(.top, ComfortaDesign.Spacing.sm)
        }
    }
    
    private var benefitsTab: some View {
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
    }
    
    private var supportTab: some View {
        ScrollView {
            LazyVStack(spacing: ComfortaDesign.Spacing.lg) {
                supportOverviewSection
                supportOptionsSection
                faqSection
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
            .padding(.top, ComfortaDesign.Spacing.sm)
        }
    }
    
    private var profileHeaderSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                // Profile Picture and Info
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    // Profile Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(userInitials)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(
                            color: ComfortaDesign.Colors.glassShadow,
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(userManager.currentUser?.fullName ?? "Usuario")
                            .font(ComfortaDesign.Typography.title2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        if let email = userManager.currentUser?.email {
                            Text(email)
                                .font(ComfortaDesign.Typography.body2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(userRating) ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundColor(index < Int(userRating) ? .yellow : ComfortaDesign.Colors.textTertiary)
                            }
                            Text(String(format: "%.1f", userRating))
                                .font(ComfortaDesign.Typography.caption1)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                // Edit Profile Button
                Button(action: {
                    // Edit profile action
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Editar Perfil")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .padding(ComfortaDesign.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                            .fill(ComfortaDesign.Colors.surfaceSecondary)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var quickStatsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Estadísticas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.md) {
                    StatItem(
                        icon: "car.fill",
                        title: "Viajes",
                        value: "\(totalTrips)",
                        color: ComfortaDesign.Colors.primaryGreen
                    )
                    
                    StatItem(
                        icon: "eurosign.circle.fill",
                        title: "Gastado",
                        value: totalSpent,
                        color: ComfortaDesign.Colors.accent
                    )
                    
                    StatItem(
                        icon: "clock.fill",
                        title: "Tiempo",
                        value: totalTime,
                        color: ComfortaDesign.Colors.warning
                    )
                    
                    StatItem(
                        icon: "star.fill",
                        title: "Puntos",
                        value: "\(loyaltyPoints)",
                        color: .yellow
                    )
                }
            }
        }
    }
    
    private var menuSection: some View {
        LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
            MenuCard(
                icon: "creditcard.fill",
                title: "Métodos de Pago",
                subtitle: "Gestiona tus tarjetas",
                color: ComfortaDesign.Colors.primaryGreen,
                action: { showingPaymentMethods = true }
            )
            
            MenuCard(
                icon: "bell.fill",
                title: "Notificaciones",
                subtitle: "Preferencias de alertas",
                color: ComfortaDesign.Colors.accent,
                action: { showingSettings = true }
            )
            
            MenuCard(
                icon: "questionmark.circle.fill",
                title: "Ayuda y Soporte",
                subtitle: "Contacta con nosotros",
                color: ComfortaDesign.Colors.warning,
                action: { showingSupport = true }
            )
            
            MenuCard(
                icon: "gearshape.fill",
                title: "Configuración",
                subtitle: "Ajustes de la aplicación",
                color: ComfortaDesign.Colors.textSecondary,
                action: { showingSettings = true }
            )
            
            MenuCard(
                icon: "power.circle.fill",
                title: "Cerrar Sesión",
                subtitle: "Salir de la aplicación",
                color: ComfortaDesign.Colors.error,
                action: {
                    userManager.signOut()
                }
            )
        }
    }
    
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
    
    private var supportOverviewSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Image(systemName: "lifepreserver")
                        .font(.largeTitle)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(ComfortaDesign.Colors.surfaceSecondary))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estamos para ayudarte")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text("Soporte 24/7 por chat, llamada o email")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                }
                
                Button(action: { showingSupport = true }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Abrir chat de soporte")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(ComfortaDesign.Radius.md)
                }
            }
        }
    }
    
    private var supportOptionsSection: some View {
        LazyVStack(spacing: ComfortaDesign.Spacing.sm) {
            SupportOptionRow(icon: "phone.fill", title: "Llamada de emergencia", subtitle: "Atención inmediata 24/7", action: { showingSupport = true })
            SupportOptionRow(icon: "envelope.fill", title: "Enviar correo", subtitle: "support@comforta.app", action: { showingSupport = true })
            SupportOptionRow(icon: "doc.text.fill", title: "Centro de ayuda", subtitle: "Preguntas frecuentes", action: { showingSupport = true })
        }
    }
    
    private var faqSection: some View {
        ModernCard(style: .surface) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                Text("FAQs rápidas")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                ForEach(supportFAQs) { faq in
                    SupportFAQRow(faq: faq)
                }
            }
        }
    }
    private var appInfoSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "car.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comforta")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("Versión 1.0.0 (Build 1)")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                VStack(spacing: ComfortaDesign.Spacing.xs) {
                    Text("© 2025 Comforta. Todos los derechos reservados.")
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: ComfortaDesign.Spacing.lg) {
                        Button("Términos") {}
                        Button("Privacidad") {}
                        Button("Soporte") {}
                    }
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
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
    
    private var userRating: Double {
        userManager.currentUser?.rating ?? 5.0
    }
    
    private var totalTrips: Int {
        userManager.currentUser?.totalTrips ?? 0
    }
    
    private var totalSpent: String {
        let amount = userManager.currentUser?.totalSpent ?? 0
        return String(format: "€%.0f", amount)
    }
    
    private var totalTime: String {
        // Placeholder - would calculate from trip history
        return "24h"
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
    
    private var supportFAQs: [SupportFAQ] {
        [
            SupportFAQ(question: "¿Cómo modifico un viaje programado?", answer: "Desde tus viajes activos, selecciona 'Editar viaje' y ajusta la hora o dirección."),
            SupportFAQ(question: "¿Cuándo llega mi reembolso?", answer: "Los reembolsos tardan entre 3 y 5 días hábiles según el método de pago."),
            SupportFAQ(question: "¿Puedo compartir mi ruta en vivo?", answer: "Sí, en la pantalla principal encontrarás 'Compartir ruta' con familiares o amigos.")
        ]
    }
}

struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
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

struct SupportOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            ModernCard(style: .glass) {
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(ComfortaDesign.Colors.surfaceSecondary))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Text(subtitle)
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SupportFAQRow: View {
    let faq: SupportFAQ
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.xs) {
            HStack {
                Text(faq.question)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }
        }
        .padding(.vertical, ComfortaDesign.Spacing.xs)
    }
}

struct ProfileAchievement: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct SupportFAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct MenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            ModernCard(style: .glass) {
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(color.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text(subtitle)
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Placeholder views for sheet presentations
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Configuración")
                .navigationTitle("Configuración")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cerrar") { dismiss() }
                    }
                }
        }
    }
}

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Ayuda y Soporte")
                .navigationTitle("Soporte")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cerrar") { dismiss() }
                    }
                }
        }
    }
}

struct PaymentMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Métodos de Pago")
                .navigationTitle("Métodos de Pago")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cerrar") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ProfileView()
}
