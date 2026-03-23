import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: TabBarItem
    let tabs: [TabBarItem]
    let onSearch: (() -> Void)?
    @Namespace private var tabNamespace
    
    init(
        selectedTab: Binding<TabBarItem>,
        tabs: [TabBarItem],
        onSearch: (() -> Void)? = nil
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.onSearch = onSearch
    }
    
    var body: some View {
        HStack(spacing: ComfortaDesign.Spacing.xs) {
            tabRow
            
            if let onSearch = onSearch {
                searchButton(onTap: onSearch)
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.xs)
    }
    
    private var tabRow: some View {
        HStack(spacing: ComfortaDesign.Spacing.xs) {
            ForEach(tabs, id: \.rawValue) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabNamespace,
                    action: {
                        withAnimation(ComfortaDesign.Animation.spring) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, ComfortaDesign.Spacing.xs)
        .padding(.vertical, ComfortaDesign.Spacing.xs)
        .frame(height: 48)
        .ultraLiquidGlass(
            cornerRadius: 18,
            intensity: 1.0,
            highlightOpacity: 0.55
        )
    }
    
    @ViewBuilder
    private func searchButton(onTap: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            onTap()
        }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
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
                        .overlay(
                            Circle()
                                .stroke(ComfortaDesign.Colors.glassHighlight.opacity(0.5), lineWidth: 1)
                        )
                )
                .shadow(color: ComfortaDesign.Colors.glassShadow.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabBarButton: View {
    let tab: TabBarItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(activeGradient)
                        .matchedGeometryEffect(id: "tabHighlight", in: namespace)
                        .shadow(
                            color: ComfortaDesign.Colors.glassShadow.opacity(0.25),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                }
                
                VStack(spacing: ComfortaDesign.Spacing.xs) {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(iconColor)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(ComfortaDesign.Animation.fast, value: isPressed)
                        .animation(ComfortaDesign.Animation.spring, value: isSelected)
                    
                    Text(tab.title)
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(labelColor)
                }
                .padding(.vertical, ComfortaDesign.Spacing.xs)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, ComfortaDesign.Spacing.xs)
            .overlay(
                Capsule()
                    .stroke(isSelected ? ComfortaDesign.Colors.glassHighlight.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(ComfortaDesign.Animation.fast) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var iconColor: Color {
        isSelected 
            ? ComfortaDesign.Colors.primaryGreen 
            : ComfortaDesign.Colors.textSecondary
    }
    
    private var labelColor: Color {
        isSelected 
            ? .white
            : ComfortaDesign.Colors.textSecondary
    }
    
    private var activeGradient: LinearGradient {
        LinearGradient(
            colors: [
                ComfortaDesign.Colors.primaryGreen,
                ComfortaDesign.Colors.darkGreen
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum TabBarItem: String, CaseIterable {
    case map = "map"
    case trips = "trips"
    case benefits = "benefits"
    case profile = "profile"

    var title: String {
        switch self {
        case .map:
            return "Mapa"
        case .trips:
            return "Viajes"
        case .benefits:
            return "Beneficios"
        case .profile:
            return "Perfil"
        }
    }

    var icon: String {
        switch self {
        case .map:
            return "map"
        case .trips:
            return "car.circle"
        case .benefits:
            return "star.circle"
        case .profile:
            return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .map:
            return "map.fill"
        case .trips:
            return "car.circle.fill"
        case .benefits:
            return "star.circle.fill"
        case .profile:
            return "person.circle.fill"
        }
    }
}

#Preview {
    @State var selectedTab: TabBarItem = .map
    
    return VStack {
        Spacer()
        GlassTabBar(
            selectedTab: $selectedTab,
            tabs: TabBarItem.allCases
        )
        .padding(.bottom, ComfortaDesign.Spacing.xl)
    }
    .background(ComfortaDesign.Colors.background)
}
