import SwiftUI

@main
struct FarewayApp: App {
    @StateObject private var store = FarewayStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("fareway_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.light)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}
