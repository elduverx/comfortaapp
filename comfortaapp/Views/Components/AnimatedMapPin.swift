import SwiftUI
import MapKit

/// Pin de mapa animado profesional con efectos visuales
struct AnimatedMapPin: View {
    let type: PinType
    let title: String?
    let isSelected: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Pin principal con animaciones
            ZStack {
                // Pulse effect (solo cuando está seleccionado)
                if isSelected {
                    Circle()
                        .fill(type.color.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                }

                // Shadow layer
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .black.opacity(0.3),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .blur(radius: 3)
                    .offset(y: 2)

                // Main pin circle
                ZStack {
                    // Outer ring
                    Circle()
                        .fill(type.color)
                        .frame(width: isSelected ? 50 : 44, height: isSelected ? 50 : 44)
                        .shadow(color: type.color.opacity(0.5), radius: 8, x: 0, y: 4)

                    // Inner white circle
                    Circle()
                        .fill(.white)
                        .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)

                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: isSelected ? 22 : 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [type.color, type.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .offset(y: bounceOffset)
            }

            // Pin pointer (punta del pin)
            PinPointer(color: type.color, scale: isSelected ? 1.15 : 1.0)
                .offset(y: -8 + bounceOffset)

            // Label (si existe)
            if let title = title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    .padding(.top, 4)
                    .opacity(isSelected ? 1 : 0.8)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
        }
        .onAppear {
            if isSelected {
                // Start pulse animation
                pulseScale = 1.3

                // Bounce animation
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
                ) {
                    bounceOffset = -10
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(
                        .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)
                    ) {
                        bounceOffset = 0
                    }
                }
            }
        }
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                // Bounce animation when selected
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
                ) {
                    bounceOffset = -10
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(
                        .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)
                    ) {
                        bounceOffset = 0
                    }
                }

                pulseScale = 1.3
            } else {
                pulseScale = 1.0
                bounceOffset = 0
            }
        }
    }
}

/// Punta del pin
private struct PinPointer: View {
    let color: Color
    let scale: CGFloat

    var body: some View {
        Triangle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 16 * scale, height: 12 * scale)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

/// Forma de triángulo para la punta del pin
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Pin Types

enum PinType {
    case pickup
    case destination
    case selectedLocation
    case driver

    var color: Color {
        switch self {
        case .pickup:
            return .green
        case .destination:
            return .red
        case .selectedLocation:
            return .blue
        case .driver:
            return .purple
        }
    }

    var icon: String {
        switch self {
        case .pickup:
            return "figure.walk.circle.fill"
        case .destination:
            return "flag.fill"
        case .selectedLocation:
            return "mappin.circle.fill"
        case .driver:
            return "car.fill"
        }
    }

    var title: String {
        switch self {
        case .pickup:
            return "Recogida"
        case .destination:
            return "Destino"
        case .selectedLocation:
            return "Ubicación"
        case .driver:
            return "Conductor"
        }
    }
}

// MARK: - Preview

struct AnimatedMapPin_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            AnimatedMapPin(
                type: .pickup,
                title: "Tu ubicación",
                isSelected: false
            )

            AnimatedMapPin(
                type: .destination,
                title: "Destino seleccionado",
                isSelected: true
            )

            AnimatedMapPin(
                type: .selectedLocation,
                title: "Nueva ubicación",
                isSelected: true
            )

            AnimatedMapPin(
                type: .driver,
                title: "Conductor llegando",
                isSelected: false
            )
        }
        .padding(50)
        .background(Color.gray.opacity(0.1))
    }
}
