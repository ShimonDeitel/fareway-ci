import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FarewayStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("fareway_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("fareway_default_currency_symbol") private var defaultCurrencySymbol: String = "$"
    @AppStorage("fareway_show_overage") private var showOverage: Bool = true

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: FundSheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                FWTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(FWTheme.brass)
                                Text("Fareway Pro active")
                                    .foregroundStyle(FWTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(FWTheme.brass)
                                    Text("Unlock Fareway Pro")
                                        .foregroundStyle(FWTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(FWTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(FWTheme.card)

                    Section("Trip Funds") {
                        Button {
                            if store.canAddFund(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Trip Fund", systemImage: "plus.circle")
                                .foregroundStyle(FWTheme.mercuryTop)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddFundButton")

                        if !purchases.isPro {
                            Text("\(store.funds.count)/\(FarewayStore.freeFundLimit) free trip funds used")
                                .font(.caption)
                                .foregroundStyle(FWTheme.inkFaded)
                        }
                    }
                    .listRowBackground(FWTheme.card)

                    Section("Preferences") {
                        Picker("Default currency symbol", selection: $defaultCurrencySymbol) {
                            Text("$").tag("$")
                            Text("\u{20AC}").tag("\u{20AC}")
                            Text("\u{00A3}").tag("\u{00A3}")
                            Text("\u{20AA}").tag("\u{20AA}")
                        }
                        .foregroundStyle(FWTheme.ink)
                        .accessibilityIdentifier("currencySymbolPicker")

                        Toggle(isOn: $showOverage) {
                            Label("Show over-funded amount", systemImage: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(FWTheme.ink)
                        }
                        .tint(FWTheme.teal)

                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(FWTheme.ink)
                        }
                        .tint(FWTheme.teal)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(FWTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("restorePurchasesButton")
                    }
                    .listRowBackground(FWTheme.card)

                    Section("About") {
                        Link(destination: URL(string: "https://rex-del.github.io/fareway-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(FWTheme.ink)
                        }
                        Link(destination: URL(string: "https://rex-del.github.io/fareway-site/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(FWTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(FWTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(FWTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(FWTheme.inkFaded)
                        }
                    }
                    .listRowBackground(FWTheme.card)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(FWTheme.card)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add:
                    FundEditSheet(mode: mode) { name, target, theme in
                        store.addFund(name: name, targetAmount: target, theme: theme, isPro: purchases.isPro)
                    }
                default:
                    EmptyView()
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every trip fund and deposit. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(FarewayStore())
        .environmentObject(PurchaseManager())
}
