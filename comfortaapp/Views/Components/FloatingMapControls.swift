import SwiftUI

// MARK: - Floating Map Button

struct FloatingMapButton: View {
    let icon: String
    let action: () -> Void
    let size: FloatingButtonSize
    let style: FloatingButtonStyle

    @State private var isPressed = false

    init(
        icon: String,
        size: FloatingButtonSize = .regular,
        style: FloatingButtonStyle = .white,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(style.foregroundColor)
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    Circle()
                        .fill(style.backgroundColor)
                        .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

enum FloatingButtonSize {
    case small
    case regular
    case large

    var dimension: CGFloat {
        switch self {
        case .small: return 40
        case .regular: return 48
        case .large: return 56
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .regular: return 20
        case .large: return 24
        }
    }
}

enum FloatingButtonStyle {
    case white
    case dark
    case accent

    var backgroundColor: Color {
        switch self {
        case .white:
            return .white
        case .dark:
            return Color.black.opacity(0.7)
        case .accent:
            return ComfortaDesign.Colors.primaryGreen
        }
    }

    var foregroundColor: Color {
        switch self {
        case .white:
            return .black
        case .dark:
            return .white
        case .accent:
            return .white
        }
    }

    var shadowColor: Color {
        switch self {
        case .white, .accent:
            return .black.opacity(0.15)
        case .dark:
            return .black.opacity(0.3)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .white, .dark:
            return 8
        case .accent:
            return 12
        }
    }
}

// MARK: - Map Controls Stack

struct MapControlsStack: View {
    let onCenterUser: () -> Void
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onShowMenu: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            if let onShowMenu = onShowMenu {
                FloatingMapButton(icon: "line.3.horizontal", action: onShowMenu)
            }

            Spacer()
                .frame(height: 20)

            FloatingMapButton(icon: "location.fill", action: onCenterUser)
            FloatingMapButton(icon: "plus", action: onZoomIn)
            FloatingMapButton(icon: "minus", action: onZoomOut)
        }
    }
}

// MARK: - Quick Actions Panel

struct QuickActionsPanel: View {
    let actions: [QuickAction]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(actions) { action in
                    MapQuickActionButton(action: action)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct MapQuickActionButton: View {
    let action: QuickAction

    var body: some View {
        Button(action: action.action) {
            HStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(action.title)
                    .font(ComfortaDesign.Typography.caption1)
            }
            .foregroundColor(action.isHighlighted ? .white : ComfortaDesign.Colors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(action.isHighlighted ? ComfortaDesign.Colors.primaryGreen : Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let isHighlighted: Bool
    let action: () -> Void

    init(icon: String, title: String, isHighlighted: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isHighlighted = isHighlighted
        self.action = action
    }
}

// MARK: - Location Status Badge

struct LocationStatusBadge: View {
    let status: LocationStatus
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(status.color)

            Text(message)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(ComfortaDesign.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

enum LocationStatus {
    case searching
    case found
    case error

    var icon: String {
        switch self {
        case .searching:
            return "location.circle"
        case .found:
            return "location.fill"
        case .error:
            return "location.slash"
        }
    }

    var color: Color {
        switch self {
        case .searching:
            return ComfortaDesign.Colors.accent
        case .found:
            return ComfortaDesign.Colors.primaryGreen
        case .error:
            return ComfortaDesign.Colors.error
        }
    }
}

// MARK: - Profile Button

struct ProfileButton: View {
    let userName: String
    let action: () -> Void

    var userInitials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if let first = components.first {
            return String(first.prefix(2))
        }
        return "U"
    }

    var body: some View {
        Button(action: action) {
            Text(userInitials.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ComfortaDesign.Colors.primaryGreen, ComfortaDesign.Colors.darkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Map Controls") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        VStack {
            HStack {
                Spacer()
                MapControlsStack(
                    onCenterUser: {},
                    onZoomIn: {},
                    onZoomOut: {},
                    onShowMenu: {}
                )
                .padding()
            }
        }
    }
}

#Preview("Quick Actions") {
    VStack {
        Spacer()
        QuickActionsPanel(actions: [
            QuickAction(icon: "house.fill", title: "Casa", action: {}),
            QuickAction(icon: "building.2.fill", title: "Trabajo", action: {}),
            QuickAction(icon: "airplane", title: "Aeropuerto", isHighlighted: true, action: {}),
            QuickAction(icon: "star.fill", title: "Guardados", action: {})
        ])
        .padding(.bottom, 20)
    }
    .background(Color.gray.opacity(0.3))
}
