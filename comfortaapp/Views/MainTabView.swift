import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabBarItem = .map
    let userName: String
    let onLogout: () -> Void
    
    var body: some View {
        TabView(selection: $selectedTab) {
            tabContainer(title: "Mapa", hidesNavigationBar: true) {
                ProfessionalRideView(
                    userName: userName,
                    onLogout: onLogout
                )
            }
            .tabItem {
                Label(TabBarItem.map.title, systemImage: TabBarItem.map.icon)
            }
            .tag(TabBarItem.map)
            
            tabContainer(title: "Viajes") {
                TripsView()
            }
            .tabItem {
                Label(TabBarItem.trips.title, systemImage: TabBarItem.trips.icon)
            }
            .tag(TabBarItem.trips)
            
            tabContainer(title: "Perfil") {
                ProfileView()
            }
            .tabItem {
                Label(TabBarItem.profile.title, systemImage: TabBarItem.profile.icon)
            }
            .tag(TabBarItem.profile)
        }
        .accentColor(ComfortaDesign.Colors.primaryGreen)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            loadSelectedTab()
        }
        .onChange(of: selectedTab) { _, newTab in
            saveSelectedTab(newTab)
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
    
    private func tabContainer<Content: View>(title: String, hidesNavigationBar: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .background(ComfortaDesign.Colors.background.ignoresSafeArea())
                .modifier(NavigationStyleModifier(title: title, hidesNavigationBar: hidesNavigationBar))
        }
    }
}

private struct NavigationStyleModifier: ViewModifier {
    let title: String
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
