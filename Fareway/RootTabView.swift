import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            FundListView()
                .tabItem {
                    Label("Home", systemImage: "thermometer.sun.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(FWTheme.mercuryTop)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(FWTheme.card)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(FarewayStore())
        .environmentObject(PurchaseManager())
}
