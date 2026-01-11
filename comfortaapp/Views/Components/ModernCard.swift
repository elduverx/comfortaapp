import SwiftUI

// MARK: - Modern Card with Liquid Glass Effect

struct ModernCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    let animation: Bool
    @State private var isHovered = false
    
    init(
        style: CardStyle = .glass,
        animation: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.animation = animation
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(ComfortaDesign.Spacing.lg)
            .background(backgroundView)
            .scaleEffect(isHovered && animation ? 1.02 : 1.0)
            .animation(ComfortaDesign.Animation.spring, value: isHovered)
            .onTapGesture {
                if animation {
                    withAnimation(ComfortaDesign.Animation.fast) {
                        isHovered = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(ComfortaDesign.Animation.fast) {
                            isHovered = false
                        }
                    }
                }
            }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .glass:
            liquidGlassBackground
        case .solid:
            solidBackground
        case .floating:
            floatingBackground
        case .surface:
            solidBackground
        }
    }
    
    private var liquidGlassBackground: some View {
        Color.clear
            .ultraLiquidGlass(
                cornerRadius: ComfortaDesign.Radius.xl,
                intensity: 0.95,
                highlightOpacity: 0.55
            )
    }
    
    private var solidBackground: some View {
        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
            .fill(ComfortaDesign.Colors.surface)
            .shadow(
                color: ComfortaDesign.Shadows.card.color,
                radius: ComfortaDesign.Shadows.card.radius,
                x: ComfortaDesign.Shadows.card.x,
                y: ComfortaDesign.Shadows.card.y
            )
    }
    
    private var floatingBackground: some View {
        RoundedRectangle(cornerRadius: ComfortaDesign.Radius.xl)
            .fill(ComfortaDesign.Colors.surface)
            .shadow(
                color: ComfortaDesign.Shadows.floating.color,
                radius: ComfortaDesign.Shadows.floating.radius,
                x: ComfortaDesign.Shadows.floating.x,
                y: ComfortaDesign.Shadows.floating.y
            )
    }
}

enum CardStyle {
    case glass
    case solid
    case floating
    case surface
}

// MARK: - Liquid Button

struct LiquidButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: LiquidButtonStyle
    let size: ButtonSize
    
    @State private var isPressed = false
    @State private var showRipple = false
    
    init(
        _ title: String,
        icon: String? = nil,
        style: LiquidButtonStyle = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(ComfortaDesign.Animation.fast) {
                isPressed = true
                showRipple = true
            }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Reset animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(ComfortaDesign.Animation.fast) {
                    isPressed = false
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showRipple = false
            }
            
            action()
        }) {
            HStack(spacing: ComfortaDesign.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(ComfortaDesign.Typography.button)
            }
            .foregroundColor(foregroundColor)
            .frame(height: size.height)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    backgroundView
                    
                    // Ripple effect
                    if showRipple {
                        Circle()
                            .fill(rippleColor)
                            .scaleEffect(showRipple ? 3 : 0)
                            .opacity(showRipple ? 0 : 1)
                            .animation(ComfortaDesign.Animation.medium, value: showRipple)
                    }
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(ComfortaDesign.Animation.spring, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            ComfortaDesign.Colors.primaryGreen,
                            ComfortaDesign.Colors.darkGreen
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: ComfortaDesign.Colors.primaryGreen.opacity(0.4),
                    radius: isPressed ? 4 : 12,
                    x: 0,
                    y: isPressed ? 2 : 6
                )
                
        case .secondary:
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(ComfortaDesign.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .stroke(ComfortaDesign.Colors.primaryGreen, lineWidth: 2)
                )
                .shadow(
                    color: ComfortaDesign.Shadows.button.color,
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
                
        case .glass:
            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            ComfortaDesign.Colors.glassBackground.opacity(0.8),
                            ComfortaDesign.Colors.glassHighlight.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                        .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(
                    color: ComfortaDesign.Colors.glassShadow,
                    radius: isPressed ? 8 : 16,
                    x: 0,
                    y: isPressed ? 4 : 8
                )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .glass:
            return ComfortaDesign.Colors.textPrimary
        }
    }
    
    private var rippleColor: Color {
        switch style {
        case .primary:
            return .white.opacity(0.3)
        case .secondary, .glass:
            return ComfortaDesign.Colors.primaryGreen.opacity(0.2)
        }
    }
}

enum LiquidButtonStyle {
    case primary
    case secondary
    case glass
}

enum ButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 48
        case .large: return 56
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(ComfortaDesign.Animation.bouncy) {
                isPressed = true
            }
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(ComfortaDesign.Animation.bouncy) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ComfortaDesign.Colors.primaryGreen,
                                    ComfortaDesign.Colors.darkGreen
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: ComfortaDesign.Colors.primaryGreen.opacity(0.4),
                            radius: isPressed ? 8 : 16,
                            x: 0,
                            y: isPressed ? 4 : 8
                        )
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(ComfortaDesign.Animation.bouncy, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
