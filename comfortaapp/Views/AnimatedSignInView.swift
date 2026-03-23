import SwiftUI
import AuthenticationServices

// MARK: - Animated Sign In View

struct AnimatedSignInView: View {
    @ObservedObject var userManager: UserManager
    let handleAuthorization: (Result<ASAuthorization, Error>) -> Void
    let handleAdminLogin: () -> Void

    @State private var backgroundOffset: CGFloat = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Animated Background with Parallax
            animatedBackground

            // Floating Particles
            floatingParticles

            // Main Content
            VStack(spacing: 48) {
                Spacer()

                // Animated Logo and Title
                logoSection
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // Sign In Card
                floatingSignInCard
                    .padding(.horizontal, 24)

                Spacer()

                // Footer
                footerSection
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Background

    private var animatedBackground: some View {
        ZStack {
            // Base Gradient
            LinearGradient(
                colors: [
                    ComfortaDesign.Colors.surface,
                    ComfortaDesign.Colors.background,
                    ComfortaDesign.Colors.primaryGreen.opacity(0.15),
                    ComfortaDesign.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Moving Gradient Overlay
            LinearGradient(
                colors: [
                    ComfortaDesign.Colors.primaryGreen.opacity(0.1),
                    .clear,
                    ComfortaDesign.Colors.lightGreen.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(y: backgroundOffset)
            .ignoresSafeArea()
        }
    }

    private var floatingParticles: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                FloatingParticle(
                    delay: Double(index) * 0.4,
                    duration: 3.0 + Double(index) * 0.5
                )
            }
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 20) {
            // App Icon with Glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ComfortaDesign.Colors.primaryGreen.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                // Logo
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(color: ComfortaDesign.Colors.primaryGreen.opacity(0.5), radius: 20, x: 0, y: 10)
            }

            // Title
            VStack(spacing: 8) {
                Text("Comforta")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white,
                                ComfortaDesign.Colors.textSecondary
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Viaje a larga distancia al precio verdadero")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Sign In Card

    private var floatingSignInCard: some View {
        VStack(spacing: ComfortaDesign.Spacing.lg) {
            // Header
            VStack(spacing: ComfortaDesign.Spacing.md) {
                Text("Bienvenido")
                    .font(ComfortaDesign.Typography.title1)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)

                Text("Conecta para unirte a los viajes premium")
                    .font(ComfortaDesign.Typography.body2)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ComfortaDesign.Spacing.lg)
            }

            // Apple Sign In Button with Custom Style
            InteractiveAppleSignInButton(
                onCompletion: handleAuthorization
            )

            // Admin Login Button
            InteractiveAdminButton(
                action: handleAdminLogin
            )

            // Error Message
            if let authError = userManager.authenticationError {
                Text(authError)
                    .foregroundColor(ComfortaDesign.Colors.error)
                    .font(ComfortaDesign.Typography.caption1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ComfortaDesign.Spacing.md)
            }
        }
        .padding(ComfortaDesign.Spacing.xl)
        .ultraLiquidGlass(
            cornerRadius: ComfortaDesign.Radius.xxl,
            intensity: 1.0,
            highlightOpacity: 0.5
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Al continuar, aceptas nuestros")
                .font(ComfortaDesign.Typography.caption2)
                .foregroundColor(ComfortaDesign.Colors.textTertiary)

            HStack(spacing: 4) {
                Button("Términos de servicio") {
                    // Handle terms
                }
                Text("y")
                Button("Política de privacidad") {
                    // Handle privacy
                }
            }
            .font(ComfortaDesign.Typography.caption2)
            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Background parallax
        withAnimation(
            .linear(duration: 20)
                .repeatForever(autoreverses: true)
        ) {
            backgroundOffset = 100
        }

        // Logo entrance
        withAnimation(
            ComfortaDesign.Animation.spring
                .delay(0.2)
        ) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
    }
}

// MARK: - Interactive Apple Sign In Button

struct InteractiveAppleSignInButton: View {
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            HapticManager.shared.impact(.medium)
            onCompletion(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .cornerRadius(ComfortaDesign.Radius.lg)
        .shadow(
            color: .black.opacity(0.2),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Interactive Admin Button

struct InteractiveAdminButton: View {
    let action: () -> Void

    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            HStack(spacing: ComfortaDesign.Spacing.md) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 18, weight: .semibold))

                Text("Iniciar como administrador")
                    .font(ComfortaDesign.Typography.body2)
            }
            .foregroundColor(isPressed ? .white : ComfortaDesign.Colors.primaryGreen.opacity(0.8))
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                    .fill(isPressed ? ComfortaDesign.Colors.primaryGreen : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                    .stroke(ComfortaDesign.Colors.primaryGreen.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(
                color: isPressed ? ComfortaDesign.Colors.primaryGreen.opacity(0.4) : .clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scale)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(ComfortaDesign.Animation.spring) {
                            isPressed = true
                            scale = 0.95
                        }
                        HapticManager.shared.impact(.light)
                    }
                }
                .onEnded { _ in
                    withAnimation(ComfortaDesign.Animation.spring) {
                        isPressed = false
                        scale = 1.0
                    }
                }
        )
    }
}

// MARK: - Floating Particle

struct FloatingParticle: View {
    let delay: Double
    let duration: Double

    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        ComfortaDesign.Colors.primaryGreen.opacity(0.3),
                        ComfortaDesign.Colors.lightGreen.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: CGFloat.random(in: 20...60), height: CGFloat.random(in: 20...60))
            .blur(radius: 20)
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                let randomX = CGFloat.random(in: -50...50)
                let randomStartY = CGFloat.random(in: -200...200)

                offsetX = randomX
                offsetY = randomStartY

                withAnimation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    offsetY = randomStartY - 150
                    opacity = 0.6
                }

                withAnimation(
                    .easeInOut(duration: duration * 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    offsetX = randomX + CGFloat.random(in: -30...30)
                }
            }
    }
}

// MARK: - Preview

#Preview {
    AnimatedSignInView(
        userManager: UserManager.shared,
        handleAuthorization: { _ in },
        handleAdminLogin: {}
    )
}
