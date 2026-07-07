import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ZStack {
                FWTheme.backdrop.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "thermometer.sun.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(FWTheme.mercuryTop)
                        .padding(.top, 40)

                    Text("Fareway Pro")
                        .font(FWTheme.titleFont)
                        .foregroundStyle(FWTheme.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("infinity", "Unlimited trip funds")
                        featureRow("paintpalette.fill", "Every trip theme, unlocked")
                        featureRow("chart.line.uptrend.xyaxis", "Deposit history and pace insights")
                        featureRow("sparkles", "Goal-reached celebration effects")
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        purchasing = true
                        Task {
                            await purchases.purchase()
                            purchasing = false
                            if purchases.isPro { dismiss() }
                        }
                    } label: {
                        HStack {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(purchases.product.map { "Subscribe for \($0.displayPrice)/month" } ?? "Unlock Pro")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FWTheme.mercuryTop)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(purchasing || purchases.product == nil)
                    .padding(.horizontal, 24)

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .font(.footnote)
                    .foregroundStyle(FWTheme.inkFaded)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(FWTheme.ink)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(FWTheme.mercuryTop)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(FWTheme.ink)
        }
    }
}

#Preview {
    PaywallView().environmentObject(PurchaseManager())
}
