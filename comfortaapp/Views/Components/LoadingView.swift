import SwiftUI

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    let style: LoadingStyle

    @State private var isAnimating = false

    init(message: String = "Cargando...", style: LoadingStyle = .fullScreen) {
        self.message = message
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .fullScreen:
                fullScreenLoader
            case .inline:
                inlineLoader
            case .overlay:
                overlayLoader
            }
        }
    }

    private var fullScreenLoader: some View {
        ZStack {
            ComfortaDesign.Colors.background
                .ignoresSafeArea()

            VStack(spacing: ComfortaDesign.Spacing.xl) {
                loadingAnimation

                Text(message)
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var inlineLoader: some View {
        HStack(spacing: ComfortaDesign.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ComfortaDesign.Colors.primaryGreen))

            Text(message)
                .font(ComfortaDesign.Typography.body2)
                .foregroundColor(ComfortaDesign.Colors.textSecondary)
        }
        .padding(.vertical, ComfortaDesign.Spacing.md)
    }

    private var overlayLoader: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            ModernCard(style: .glass) {
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    loadingAnimation

                    Text(message)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(ComfortaDesign.Spacing.lg)
            }
            .padding(.horizontal, ComfortaDesign.Spacing.xxl)
        }
    }

    private var loadingAnimation: some View {
        ZStack {
            // Outer ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            ComfortaDesign.Colors.primaryGreen,
                            ComfortaDesign.Colors.lightGreen
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // Inner dot
            Circle()
                .fill(ComfortaDesign.Colors.primaryGreen)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 1 : 0.6)
                .animation(
                    .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

enum LoadingStyle {
    case fullScreen
    case inline
    case overlay
}

// MARK: - Loading Modifier

struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)

            if isLoading {
                LoadingView(message: message, style: .overlay)
                    .transition(.opacity)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool, message: String = "Cargando...") -> some View {
        modifier(LoadingModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - Shimmer Effect for Loading States

struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    ComfortaDesign.Colors.glassHighlight.opacity(0.3),
                    Color.clear
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
        }
        .clipped()
    }
}

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(ShimmerView())
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Loading View

struct SkeletonLoadingView: View {
    var body: some View {
        VStack(spacing: ComfortaDesign.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: ComfortaDesign.Spacing.md) {
                    Circle()
                        .fill(ComfortaDesign.Colors.surfaceSecondary)
                        .frame(width: 50, height: 50)
                        .shimmer()

                    VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ComfortaDesign.Colors.surfaceSecondary)
                            .frame(height: 16)
                            .shimmer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(ComfortaDesign.Colors.surfaceSecondary)
                            .frame(width: 150, height: 12)
                            .shimmer()
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                        .fill(ComfortaDesign.Colors.surface)
                )
            }
        }
        .padding()
    }
}

#Preview("Full Screen") {
    LoadingView(message: "Buscando conductor...", style: .fullScreen)
}

#Preview("Inline") {
    VStack {
        LoadingView(message: "Calculando ruta...", style: .inline)
    }
    .padding()
    .background(ComfortaDesign.Colors.background)
}

#Preview("Overlay") {
    ZStack {
        ComfortaDesign.Colors.background.ignoresSafeArea()

        VStack {
            Text("Contenido de la app")
                .font(.title)
        }

        LoadingView(message: "Procesando pago...", style: .overlay)
    }
}

#Preview("Skeleton") {
    SkeletonLoadingView()
        .background(ComfortaDesign.Colors.background)
}
