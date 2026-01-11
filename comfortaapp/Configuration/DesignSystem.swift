import SwiftUI
import UIKit

// MARK: - Design System

struct ComfortaDesign {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary Brand Colors (blanco, negro y dorado)
        static let primaryGreen = Color(red: 0.84, green: 0.73, blue: 0.33) // Dorado principal
        static let darkGreen = Color(red: 0.66, green: 0.52, blue: 0.18) // Dorado profundo
        static let lightGreen = Color(red: 0.95, green: 0.89, blue: 0.69) // Brillo dorado
        
        // Premium Glass Colors
        static let glassBackground = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.2)
        static let glassHighlight = Color(red: 0.95, green: 0.88, blue: 0.72)
        static let glassShadow = Color.black.opacity(0.35)
        
        // Semantic Colors
        static let success = primaryGreen
        static let accent = Color(red: 0.42, green: 0.68, blue: 1.0)
        static let warning = Color(red: 1.0, green: 0.72, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let info = Color(red: 0.6, green: 0.7, blue: 0.9)
        
        // Neutral Colors
        static let background = Color(red: 0.05, green: 0.05, blue: 0.06)
        static let surface = Color(red: 0.12, green: 0.12, blue: 0.14)
        static let surfaceSecondary = Color(red: 0.09, green: 0.09, blue: 0.11)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.75)
        static let textTertiary = Color.white.opacity(0.55)
        
        // Map Colors
        static let pickupMarker = primaryGreen
        static let destinationMarker = Color.white
        static let routeLine = primaryGreen
    }
    
    // MARK: - Typography
    
    struct Typography {
        static let hero = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        static let body1 = Font.system(size: 16, weight: .medium, design: .default)
        static let body2 = Font.system(size: 14, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .medium, design: .default)
        static let caption2 = Font.system(size: 10, weight: .regular, design: .default)
        
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let glass = Shadow(
            color: .black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
        
        static let card = Shadow(
            color: .black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 4
        )
        
        static let button = Shadow(
            color: .black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let floating = Shadow(
            color: .black.opacity(0.2),
            radius: 24,
            x: 0,
            y: 12
        )
    }
    
    // MARK: - Animations
    
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.6)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        static let spring = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0
        )
        
        static let bouncy = SwiftUI.Animation.spring(
            response: 0.6,
            dampingFraction: 0.7,
            blendDuration: 0
        )
    }
}

// MARK: - Shadow Helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    func glassMorphism(
        cornerRadius: CGFloat = ComfortaDesign.Radius.lg,
        blur: CGFloat = 20
    ) -> some View {
        self
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(ComfortaDesign.Colors.glassBackground)
                        .background(
                            // Blur effect
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: cornerRadius)
                        )
                    
                    // Glass border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(ComfortaDesign.Colors.glassBorder, lineWidth: 1)
                }
            )
            .shadow(
                color: ComfortaDesign.Shadows.glass.color,
                radius: ComfortaDesign.Shadows.glass.radius,
                x: ComfortaDesign.Shadows.glass.x,
                y: ComfortaDesign.Shadows.glass.y
            )
    }
    
    func liquidGlass(
        cornerRadius: CGFloat = ComfortaDesign.Radius.xl,
        intensity: Double = 0.8
    ) -> some View {
        self
            .background(
                ZStack {
                    // Liquid glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ComfortaDesign.Colors.glassBackground.opacity(intensity),
                                    ComfortaDesign.Colors.glassHighlight.opacity(intensity * 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // Highlight edge
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ComfortaDesign.Colors.glassHighlight,
                                    ComfortaDesign.Colors.glassBorder
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: ComfortaDesign.Colors.glassShadow,
                radius: 16,
                x: 0,
                y: 8
            )
    }
    
    func ultraLiquidGlass(
        cornerRadius: CGFloat = ComfortaDesign.Radius.xl,
        intensity: Double = 1.0,
        highlightOpacity: Double = 0.45
    ) -> some View {
        self
            .background(
                ZStack {
                    // Liquid base with stronger highlights
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ComfortaDesign.Colors.glassBackground.opacity(intensity),
                                    ComfortaDesign.Colors.glassHighlight.opacity(intensity * 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            ComfortaDesign.Colors.glassHighlight.opacity(0.9),
                                            ComfortaDesign.Colors.glassBorder.opacity(0.6),
                                            ComfortaDesign.Colors.glassHighlight.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(ComfortaDesign.Colors.glassHighlight.opacity(0.2), lineWidth: 0.5)
                                .blur(radius: 1.5)
                        )
                        .overlay(
                            // Soft top-left glow
                            LinearGradient(
                                colors: [
                                    .white.opacity(highlightOpacity),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                            .blendMode(.plusLighter)
                        )
                }
            )
            .shadow(
                color: ComfortaDesign.Colors.glassShadow.opacity(0.25),
                radius: 22,
                x: 0,
                y: 12
            )
            .shadow(
                color: ComfortaDesign.Colors.glassShadow.opacity(0.18),
                radius: 32,
                x: 0,
                y: 18
            )
    }
    
    func cardStyle() -> some View {
        self
            .background(ComfortaDesign.Colors.surface)
            .cornerRadius(ComfortaDesign.Radius.lg)
            .shadow(
                color: ComfortaDesign.Shadows.card.color,
                radius: ComfortaDesign.Shadows.card.radius,
                x: ComfortaDesign.Shadows.card.x,
                y: ComfortaDesign.Shadows.card.y
            )
    }
    
}

// MARK: - Button Styles

enum ButtonStyleType {
    case primary
    case secondary
    case ghost
    case glass
}

struct ModernButtonStyle: ViewModifier {
    let style: ButtonStyleType
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .font(ComfortaDesign.Typography.button)
            .frame(height: 48)
            .padding(.horizontal, ComfortaDesign.Spacing.md)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(ComfortaDesign.Radius.md)
            .shadow(
                color: shadowColor,
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(ComfortaDesign.Animation.fast, value: isPressed)
            .onTapGesture {
                withAnimation(ComfortaDesign.Animation.fast) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(ComfortaDesign.Animation.fast) {
                        isPressed = false
                    }
                }
            }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ComfortaDesign.Colors.primaryGreen
        case .secondary:
            return ComfortaDesign.Colors.surface
        case .ghost:
            return Color.clear
        case .glass:
            return ComfortaDesign.Colors.glassBackground
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .ghost:
            return ComfortaDesign.Colors.textPrimary
        case .glass:
            return ComfortaDesign.Colors.textPrimary
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return ComfortaDesign.Colors.primaryGreen.opacity(0.3)
        case .secondary, .ghost, .glass:
            return ComfortaDesign.Colors.glassShadow
        }
    }
}
