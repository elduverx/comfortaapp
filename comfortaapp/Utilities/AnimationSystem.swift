import SwiftUI
import UIKit

// MARK: - Animation System

struct AnimationSystem {
    
    // MARK: - Preset Animations
    
    struct Preset {
        static let quickTap = Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let smoothEntry = Animation.easeInOut(duration: 0.5)
        static let bouncyEntry = Animation.spring(response: 0.6, dampingFraction: 0.7)
        static let slideIn = Animation.easeOut(duration: 0.4)
        static let fadeInOut = Animation.easeInOut(duration: 0.3)
        static let liquidMotion = Animation.spring(response: 0.8, dampingFraction: 0.8)
        
        // Page Transitions
        static let pageTransition = Animation.interpolatingSpring(
            stiffness: 300,
            damping: 30,
            initialVelocity: 0
        )
        
        // Glass Effects
        static let glassRipple = Animation.easeOut(duration: 0.6)
        static let glassShimmer = Animation.linear(duration: 2.0).repeatForever(autoreverses: true)
    }
    
    // MARK: - Interactive Animations
    
    static func buttonPressAnimation<T: View>(
        _ content: T,
        action: @escaping () -> Void
    ) -> some View {
        InteractiveButton(content: content, action: action)
    }
    
    static func cardHoverAnimation<T: View>(_ content: T) -> some View {
        HoverableCard(content: content)
    }
    
    static func liquidWaveAnimation<T: View>(_ content: T) -> some View {
        LiquidWaveView(content: content)
    }
}

// MARK: - Interactive Button

private struct InteractiveButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var brightness: Double = 0.0
    
    var body: some View {
        content
            .scaleEffect(scale)
            .brightness(brightness)
            .onTapGesture {
                performTapAnimation()
                action()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
                withAnimation(AnimationSystem.Preset.quickTap) {
                    isPressed = pressing
                    scale = pressing ? 0.95 : 1.0
                    brightness = pressing ? -0.1 : 0.0
                }
            } perform: {}
    }
    
    private func performTapAnimation() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Visual feedback
        withAnimation(AnimationSystem.Preset.quickTap) {
            scale = 0.92
            brightness = -0.15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(AnimationSystem.Preset.quickTap) {
                scale = 1.0
                brightness = 0.0
            }
        }
    }
}

// MARK: - Hoverable Card

private struct HoverableCard<Content: View>: View {
    let content: Content
    
    @State private var isHovered = false
    @State private var shadowRadius: CGFloat = 8
    @State private var shadowY: CGFloat = 4
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        content
            .scaleEffect(scale)
            .shadow(
                color: ComfortaDesign.Colors.glassShadow,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .onTapGesture {
                performHoverAnimation()
            }
    }
    
    private func performHoverAnimation() {
        withAnimation(AnimationSystem.Preset.liquidMotion) {
            isHovered.toggle()
            scale = isHovered ? 1.02 : 1.0
            shadowRadius = isHovered ? 16 : 8
            shadowY = isHovered ? 8 : 4
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AnimationSystem.Preset.liquidMotion) {
                isHovered = false
                scale = 1.0
                shadowRadius = 8
                shadowY = 4
            }
        }
    }
}

// MARK: - Liquid Wave Animation

private struct LiquidWaveView<Content: View>: View {
    let content: Content
    
    @State private var waveOffset1 = 0.0
    @State private var waveOffset2 = 0.0
    @State private var waveOffset3 = 0.0
    
    var body: some View {
        content
            .overlay(
                ZStack {
                    WaveShape(offset: waveOffset1, amplitude: 0.02, frequency: 1.0)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ComfortaDesign.Colors.primaryGreen.opacity(0.1),
                                    ComfortaDesign.Colors.lightGreen.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blendMode(.overlay)
                    
                    WaveShape(offset: waveOffset2, amplitude: 0.03, frequency: 0.8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ComfortaDesign.Colors.glassHighlight.opacity(0.1),
                                    ComfortaDesign.Colors.primaryGreen.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.softLight)
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                startWaveAnimations()
            }
    }
    
    private func startWaveAnimations() {
        withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            waveOffset1 = 2 * .pi
        }
        
        withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            waveOffset2 = 2 * .pi
        }
        
        withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
            waveOffset3 = 2 * .pi
        }
    }
}

// MARK: - Wave Shape

private struct WaveShape: Shape {
    let offset: Double
    let amplitude: Double
    let frequency: Double
    
    var animatableData: Double {
        get { offset }
        set { }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = midHeight + amplitude * height * sin(frequency * 2 * .pi * relativeX + offset)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var shimmerPosition: CGFloat = -1
    let duration: Double
    let angle: Double
    
    init(duration: Double = 2.0, angle: Double = 20) {
        self.duration = duration
        self.angle = angle
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                ComfortaDesign.Colors.glassHighlight.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(angle))
                    .offset(x: shimmerPosition * 300)
                    .animation(
                        Animation.linear(duration: duration).repeatForever(autoreverses: false),
                        value: shimmerPosition
                    )
                    .allowsHitTesting(false)
            )
            .onAppear {
                shimmerPosition = 1
            }
    }
}

// MARK: - Breathing Animation

struct BreathingAnimation: ViewModifier {
    @State private var isBreathing = false
    let duration: Double
    let scaleRange: ClosedRange<CGFloat>
    
    init(duration: Double = 3.0, scaleRange: ClosedRange<CGFloat> = 0.95...1.05) {
        self.duration = duration
        self.scaleRange = scaleRange
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? scaleRange.upperBound : scaleRange.lowerBound)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

// MARK: - Floating Animation

struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 10, duration: Double = 2.0) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                withAnimation {
                    isFloating = true
                }
            }
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let duration: Double
    
    init(color: Color = ComfortaDesign.Colors.primaryGreen, duration: Double = 1.5) {
        self.color = color
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.5 : 1)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: duration).repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Morphing Background

struct MorphingBackground: View {
    @State private var gradientOffset = 0.0
    @State private var colorShift = 0.0
    
    let colors: [Color]
    let duration: Double
    
    init(colors: [Color]? = nil, duration: Double = 8.0) {
        self.colors = colors ?? [
            ComfortaDesign.Colors.background,
            ComfortaDesign.Colors.surfaceSecondary,
            ComfortaDesign.Colors.primaryGreen.opacity(0.1),
            ComfortaDesign.Colors.glassBackground
        ]
        self.duration = duration
    }
    
    var body: some View {
        // Fallback to regular gradient since MeshGradient requires iOS 18+
        LinearGradient(
            colors: animatedColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .onAppear {
            startAnimations()
        }
    }
    
    private var animatedPoints: [SIMD2<Float>] {
        [
            [0, 0], [0.5 + Float(sin(gradientOffset) * 0.1), 0],
            [1, 0], [Float(sin(gradientOffset + 1) * 0.1), 0.5],
            [0.5 + Float(cos(gradientOffset) * 0.1), 0.5],
            [1 + Float(sin(gradientOffset + 2) * 0.1), 0.5],
            [0, 1], [0.5 + Float(cos(gradientOffset + 1.5) * 0.1), 1],
            [1, 1]
        ]
    }
    
    private var animatedColors: [Color] {
        colors.indices.map { index in
            colors[index].opacity(0.8 + 0.2 * sin(colorShift + Double(index)))
        } + colors
    }
    
    private func startAnimations() {
        withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: true)) {
            gradientOffset = 2 * .pi
        }
        
        withAnimation(Animation.linear(duration: duration * 1.5).repeatForever(autoreverses: true)) {
            colorShift = 2 * .pi
        }
    }
}

// MARK: - View Extensions

extension View {
    func shimmerEffect(duration: Double = 2.0, angle: Double = 20) -> some View {
        self.modifier(ShimmerEffect(duration: duration, angle: angle))
    }
    
    func breathingAnimation(duration: Double = 3.0, scaleRange: ClosedRange<CGFloat> = 0.95...1.05) -> some View {
        self.modifier(BreathingAnimation(duration: duration, scaleRange: scaleRange))
    }
    
    func floatingAnimation(amplitude: CGFloat = 10, duration: Double = 2.0) -> some View {
        self.modifier(FloatingAnimation(amplitude: amplitude, duration: duration))
    }
    
    func pulseAnimation(color: Color = ComfortaDesign.Colors.primaryGreen, duration: Double = 1.5) -> some View {
        self.modifier(PulseAnimation(color: color, duration: duration))
    }
    
    func interactivePress(action: @escaping () -> Void) -> some View {
        AnimationSystem.buttonPressAnimation(self, action: action)
    }
    
    func hoverableCard() -> some View {
        AnimationSystem.cardHoverAnimation(self)
    }
    
    func liquidWave() -> some View {
        AnimationSystem.liquidWaveAnimation(self)
    }
}