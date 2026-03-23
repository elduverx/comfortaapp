import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingSettings = false
    @State private var showingSupport = false
    @State private var showingPaymentMethods = false
    @State private var showingEditProfile = false
    @State private var showingStats = false
    @State private var showingNotifications = false
    @State private var showingSignOutConfirm = false
    @State private var isViewReady = false
    @State private var selectedProfileTab = 0

    var body: some View {
        TabView(selection: $selectedProfileTab) {
            overviewTab
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(0)

            supportTab
                .tabItem {
                    Label("Soporte", systemImage: "questionmark.circle.fill")
                }
                .tag(1)
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
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingStats) {
            ProfileStatsView()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
        .alert("Cerrar sesión", isPresented: $showingSignOutConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) {
                userManager.signOut()
            }
        } message: {
            Text("¿Seguro que quieres cerrar sesión?")
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingEditProfile = true
                    }
                    
                    Spacer()
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                // Edit Profile Button
                Button(action: {
                    showingEditProfile = true
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
        Button(action: {
            showingStats = true
        }) {
            ModernCard(style: .glass) {
                VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                    HStack {
                        Text("Estadísticas")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    }
                    
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
        .buttonStyle(PlainButtonStyle())
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
                action: { showingNotifications = true }
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
                    showingSignOutConfirm = true
                }
            )
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

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    @State private var preferences = UserPreferences()
    @State private var didLoad = false

    private let languages = [
        ("es", "Español"),
        ("en", "English"),
        ("fr", "Français")
    ]

    private let currencies = [
        ("EUR", "EUR (€)"),
        ("USD", "USD ($)"),
        ("GBP", "GBP (£)")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferencias") {
                    Picker("Idioma", selection: $preferences.language) {
                        ForEach(languages, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }

                    Picker("Moneda", selection: $preferences.currency) {
                        ForEach(currencies, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                }

                Section("Privacidad") {
                    Toggle("Compartir datos de ubicación", isOn: $preferences.privacy.shareLocationData)
                    Toggle("Compartir datos de uso", isOn: $preferences.privacy.shareUsageData)
                    Toggle("Permitir marketing", isOn: $preferences.privacy.allowMarketing)
                }

                Section("Accesibilidad") {
                    Toggle("VoiceOver", isOn: $preferences.accessibility.voiceOver)
                    Toggle("Texto grande", isOn: $preferences.accessibility.largeText)
                    Toggle("Alto contraste", isOn: $preferences.accessibility.highContrast)
                    Toggle("Reducir movimiento", isOn: $preferences.accessibility.reducedMotion)
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { savePreferences() }
                }
            }
            .onAppear {
                if !didLoad {
                    preferences = userManager.currentUser?.preferences ?? UserPreferences()
                    didLoad = true
                }
            }
        }
    }

    private func savePreferences() {
        userManager.updateUserProfile(preferences: preferences)
        dismiss()
    }
}

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let faqs = [
        SupportFAQ(question: "¿Cómo cambio mi método de pago?", answer: "En Perfil > Métodos de Pago puedes añadir o cambiar el predeterminado."),
        SupportFAQ(question: "¿Puedo cancelar un viaje?", answer: "Sí, desde la pantalla del viaje en curso puedes cancelar antes de que el conductor llegue."),
        SupportFAQ(question: "¿Dónde veo mis recibos?", answer: "En la sección de Viajes, entra en un viaje y verás el recibo.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Contacto directo") {
                    SupportActionRow(
                        icon: "phone.fill",
                        title: "Llamar a soporte",
                        subtitle: "+34 900 000 000"
                    ) {
                        openURL(URL(string: "tel://900000000")!)
                    }

                    SupportActionRow(
                        icon: "envelope.fill",
                        title: "Enviar correo",
                        subtitle: "support@comforta.app"
                    ) {
                        openURL(URL(string: "mailto:support@comforta.app")!)
                    }

                    SupportActionRow(
                        icon: "message.fill",
                        title: "Chat en vivo",
                        subtitle: "Respuesta en minutos"
                    ) {
                        openURL(URL(string: "mailto:support@comforta.app?subject=Chat%20Comforta")!)
                    }
                }

                Section("Centro de ayuda") {
                    SupportActionRow(
                        icon: "doc.text.fill",
                        title: "Preguntas frecuentes",
                        subtitle: "Respuestas rápidas"
                    ) {}

                    SupportActionRow(
                        icon: "exclamationmark.bubble.fill",
                        title: "Reportar un problema",
                        subtitle: "Cuéntanos qué pasó"
                    ) {
                        openURL(URL(string: "mailto:support@comforta.app?subject=Reporte%20de%20problema")!)
                    }
                }

                Section("FAQs") {
                    ForEach(faqs) { faq in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(faq.question)
                                .font(ComfortaDesign.Typography.body2)
                            Text(faq.answer)
                                .font(ComfortaDesign.Typography.caption2)
                                .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ayuda y soporte")
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
    @EnvironmentObject private var userManager: UserManager
    @State private var methods: [PaymentMethodEntry] = []
    @State private var showingAdd = false
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            List {
                if methods.isEmpty {
                    Text("No tienes métodos de pago guardados.")
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                } else {
                    ForEach(methods) { method in
                        PaymentMethodRow(
                            method: method,
                            onSetDefault: {
                                setDefault(method)
                            },
                            onDelete: {
                                deleteMethod(method)
                            }
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Métodos de pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir") { showingAdd = true }
                }
            }
            .onAppear {
                if !didLoad {
                    loadMethods()
                    didLoad = true
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddPaymentMethodView { newMethod in
                    addMethod(newMethod)
                }
            }
        }
    }

    private func loadMethods() {
        let key = storageKey()
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PaymentMethodEntry].self, from: data) {
            methods = decoded
        } else {
            methods = [PaymentMethodEntry(type: .cash, last4: nil, nickname: "Efectivo", isDefault: true)]
            saveMethods()
        }
        ensureDefaultMethod()
    }

    private func saveMethods() {
        let key = storageKey()
        if let encoded = try? JSONEncoder().encode(methods) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func storageKey() -> String {
        let userId = userManager.currentUser?.id ?? "guest"
        return "payment_methods_\(userId)"
    }

    private func ensureDefaultMethod() {
        if methods.first(where: { $0.isDefault }) == nil, let first = methods.first {
            setDefault(first)
        } else if let defaultMethod = methods.first(where: { $0.isDefault }) {
            userManager.updatePaymentMethod(defaultMethod.type)
        }
    }

    private func addMethod(_ method: PaymentMethodEntry) {
        if method.isDefault {
            methods = methods.map { PaymentMethodEntry(id: $0.id, type: $0.type, last4: $0.last4, nickname: $0.nickname, isDefault: false) }
        }
        methods.append(method)
        if method.isDefault || methods.count == 1 {
            setDefault(method)
        } else {
            saveMethods()
        }
    }

    private func setDefault(_ method: PaymentMethodEntry) {
        methods = methods.map {
            PaymentMethodEntry(
                id: $0.id,
                type: $0.type,
                last4: $0.last4,
                nickname: $0.nickname,
                isDefault: $0.id == method.id
            )
        }
        userManager.updatePaymentMethod(method.type)
        saveMethods()
    }

    private func deleteMethod(_ method: PaymentMethodEntry) {
        methods.removeAll { $0.id == method.id }
        if method.isDefault, let newDefault = methods.first {
            setDefault(newDefault)
        } else {
            saveMethods()
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos personales") {
                    TextField("Nombre", text: $firstName)
                    TextField("Apellidos", text: $lastName)
                    TextField("Teléfono", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Contacto") {
                    Text(email.isEmpty ? "Sin email" : email)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { saveProfile() }
                }
            }
            .onAppear {
                if !didLoad {
                    loadProfile()
                    didLoad = true
                }
            }
        }
    }

    private func loadProfile() {
        guard let user = userManager.currentUser else { return }
        firstName = user.firstName
        lastName = user.lastName
        phoneNumber = user.phoneNumber ?? ""
        email = user.email ?? ""
    }

    private func saveProfile() {
        userManager.updateUserProfile(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber
        )
        dismiss()
    }
}

struct ProfileStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager

    var body: some View {
        NavigationStack {
            List {
                Section("Resumen") {
                    StatRow(label: "Viajes", value: "\(totalTrips)")
                    StatRow(label: "Gastado", value: totalSpent)
                    StatRow(label: "Tiempo", value: totalTime)
                    StatRow(label: "Puntos", value: "\(loyaltyPoints)")
                    StatRow(label: "Valoración", value: String(format: "%.1f", userRating))
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private var totalTrips: Int {
        userManager.currentUser?.totalTrips ?? 0
    }

    private var totalSpent: String {
        let amount = userManager.currentUser?.totalSpent ?? 0
        return String(format: "€%.0f", amount)
    }

    private var totalTime: String {
        "24h"
    }

    private var loyaltyPoints: Int {
        userManager.currentUser?.loyaltyPoints ?? 0
    }

    private var userRating: Double {
        userManager.currentUser?.rating ?? 5.0
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    @State private var preferences = UserPreferences()
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Pausar todas", isOn: pauseAllBinding)
                } footer: {
                    Text("Si pausas todas, no recibirás avisos importantes del viaje.")
                }

                Section("Canales") {
                    Toggle("Notificaciones push", isOn: $preferences.notifications.pushNotifications)
                    Toggle("Email", isOn: $preferences.notifications.emailNotifications)
                    Toggle("SMS", isOn: $preferences.notifications.smsNotifications)
                }

                Section("Alertas") {
                    Toggle("Actualizaciones de viaje", isOn: $preferences.notifications.rideUpdates)
                    Toggle("Promociones y novedades", isOn: $preferences.notifications.promotions)
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { savePreferences() }
                }
            }
            .onAppear {
                if !didLoad {
                    preferences = userManager.currentUser?.preferences ?? UserPreferences()
                    didLoad = true
                }
            }
        }
    }

    private var pauseAllBinding: Binding<Bool> {
        Binding(
            get: { notificationsPaused },
            set: { paused in
                if paused {
                    disableAllNotifications()
                } else {
                    restoreDefaultNotifications()
                }
            }
        )
    }

    private var notificationsPaused: Bool {
        let notif = preferences.notifications
        return !notif.pushNotifications &&
            !notif.emailNotifications &&
            !notif.smsNotifications &&
            !notif.rideUpdates &&
            !notif.promotions
    }

    private func disableAllNotifications() {
        preferences.notifications.pushNotifications = false
        preferences.notifications.emailNotifications = false
        preferences.notifications.smsNotifications = false
        preferences.notifications.rideUpdates = false
        preferences.notifications.promotions = false
    }

    private func restoreDefaultNotifications() {
        preferences.notifications.pushNotifications = true
        preferences.notifications.emailNotifications = true
        preferences.notifications.smsNotifications = false
        preferences.notifications.rideUpdates = true
        preferences.notifications.promotions = false
    }

    private func savePreferences() {
        userManager.updateUserProfile(preferences: preferences)
        dismiss()
    }
}

private struct SupportActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    Text(subtitle)
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ComfortaDesign.Colors.textTertiary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentMethodEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var type: PaymentType
    var last4: String?
    var nickname: String?
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        type: PaymentType,
        last4: String?,
        nickname: String?,
        isDefault: Bool
    ) {
        self.id = id
        self.type = type
        self.last4 = last4
        self.nickname = nickname
        self.isDefault = isDefault
    }

    var displayName: String {
        if let nickname, !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nickname
        }
        return type.displayName
    }

    var detailText: String {
        if let last4, !last4.isEmpty {
            return "•••• \(last4)"
        }
        switch type {
        case .cash:
            return "Pago en efectivo"
        case .applePay:
            return "Apple Pay"
        case .creditCard:
            return "Tarjeta"
        }
    }
}

private struct PaymentMethodRow: View {
    let method: PaymentMethodEntry
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: method.type.iconName)
                .font(.system(size: 18))
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(method.displayName)
                        .font(ComfortaDesign.Typography.body2)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)

                    if method.isDefault {
                        Text("Predeterminado")
                            .font(ComfortaDesign.Typography.caption2)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(ComfortaDesign.Colors.primaryGreen.opacity(0.15))
                            )
                    }
                }

                Text(method.detailText)
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
            }

            Spacer()

            if !method.isDefault {
                Button("Predeterminado") {
                    onSetDefault()
                }
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.primaryGreen)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !method.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Predeterminado", systemImage: "checkmark.circle")
                }
                .tint(ComfortaDesign.Colors.primaryGreen)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

private struct AddPaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var type: PaymentType = .creditCard
    @State private var last4 = ""
    @State private var nickname = ""
    @State private var isDefault = true
    let onSave: (PaymentMethodEntry) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo de método") {
                    Picker("Método", selection: $type) {
                        ForEach(PaymentType.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                }

                Section("Detalles") {
                    TextField("Nombre para identificar", text: $nickname)

                    if type == .creditCard {
                        TextField("Últimos 4 dígitos", text: $last4)
                            .keyboardType(.numberPad)
                            .onChange(of: last4) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 4 {
                                    last4 = String(filtered.prefix(4))
                                } else {
                                    last4 = filtered
                                }
                            }
                    }
                }

                Section {
                    Toggle("Marcar como predeterminado", isOn: $isDefault)
                }
            }
            .navigationTitle("Añadir método")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { saveMethod() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        if type == .creditCard {
            return last4.count == 4
        }
        return true
    }

    private func saveMethod() {
        let trimmedName = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = PaymentMethodEntry(
            type: type,
            last4: last4.isEmpty ? nil : last4,
            nickname: trimmedName.isEmpty ? nil : trimmedName,
            isDefault: isDefault
        )
        onSave(entry)
        dismiss()
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView()
}
