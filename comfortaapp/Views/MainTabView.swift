import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabBarItem = .map
    let userName: String
    let onLogout: () -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            tabContainer(title: "Mapa", hidesNavigationBar: true) {
                RideHomeView(
                    userName: userName,
                    onLogout: onLogout,
                    onProfileTap: {
                        selectedTab = .profile
                    }
                )
            }
            .tabItem {
                Label("Mapa", systemImage: "map")
            }
            .tag(TabBarItem.map)

            tabContainer(title: "Viajes") {
                TripsView()
            }
            .tabItem {
                Label("Viajes", systemImage: "car.circle")
            }
            .tag(TabBarItem.trips)

            tabContainer(title: "Beneficios") {
                BenefitsView()
            }
            .tabItem {
                Label("Beneficios", systemImage: "star.circle")
            }
            .tag(TabBarItem.benefits)

            tabContainer(title: "Perfil") {
                ProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.circle")
            }
            .tag(TabBarItem.profile)
        }
        .accentColor(ComfortaDesign.Colors.primaryGreen)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            loadSelectedTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showActiveTrip)) { _ in
            selectedTab = .map
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTripDetails)) { _ in
            selectedTab = .map
        }
        .onChange(of: selectedTab) { _, newTab in
            saveSelectedTab(newTab)
            HapticManager.shared.impact(.light)
        }
    }
    
    private func loadSelectedTab() {
        if let savedTab = UserDefaults.standard.string(forKey: "selected_tab"),
           let tab = TabBarItem(rawValue: savedTab) {
            selectedTab = tab
        }
    }
    
    private func saveSelectedTab(_ tab: TabBarItem) {
        UserDefaults.standard.set(tab.rawValue, forKey: "selected_tab")
    }
    
    private func tabContainer<Content: View>(title: LocalizedStringKey, hidesNavigationBar: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .background(ComfortaDesign.Colors.background.ignoresSafeArea())
                .modifier(NavigationStyleModifier(title: title, hidesNavigationBar: hidesNavigationBar))
        }
    }
}

private struct NavigationStyleModifier: ViewModifier {
    let title: LocalizedStringKey
    let hidesNavigationBar: Bool
    
    func body(content: Content) -> some View {
        if hidesNavigationBar {
            content
                .toolbar(.hidden, for: .navigationBar)
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MainTabView(
        userName: "Usuario Test",
        onLogout: {}
    )
}
