import SwiftUI

struct FundListView: View {
    @EnvironmentObject private var store: FarewayStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: FundSheetMode?
    @State private var deletingFund: TripFund?
    @State private var savedToast: String?
    @State private var celebratingFundID: UUID?

    private var sortedFunds: [TripFund] {
        store.funds.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FWTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if store.funds.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                                ForEach(sortedFunds) { fund in
                                    TripFundCard(
                                        fund: fund,
                                        isCelebrating: celebratingFundID == fund.id
                                    ) {
                                        sheetMode = .deposit(fund)
                                    } onEdit: {
                                        sheetMode = .edit(fund)
                                    } onDelete: {
                                        Haptics.warning()
                                        deletingFund = fund
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.funds)

                            if !purchases.isPro {
                                Text("Free plan: \(store.funds.count)/\(FarewayStore.freeFundLimit) trip funds used")
                                    .font(.caption)
                                    .foregroundStyle(FWTheme.inkFaded)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                if let name = savedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                            Text(name)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(FWTheme.teal)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    FundEditSheet(mode: mode) { name, target, theme in
                        switch mode {
                        case .add:
                            store.addFund(name: name, targetAmount: target, theme: theme, isPro: purchases.isPro)
                            Haptics.success()
                            showToast("Trip fund created")
                        case .edit(let fund):
                            store.updateFund(fund.id, name: name, targetAmount: target, theme: theme)
                        default:
                            break
                        }
                    }
                case .deposit(let fund):
                    DepositLogSheet(fund: fund) { amount, date, note in
                        let crossedGoal = store.logDeposit(fundID: fund.id, amount: amount, date: date, note: note)
                        Haptics.success()
                        showToast("Deposit logged")
                        if crossedGoal {
                            celebratingFundID = fund.id
                            Task {
                                try? await Task.sleep(nanoseconds: 1_600_000_000)
                                if celebratingFundID == fund.id { celebratingFundID = nil }
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                "Remove \(deletingFund?.name ?? "")?",
                isPresented: Binding(
                    get: { deletingFund != nil },
                    set: { if !$0 { deletingFund = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deletingFund {
                        store.deleteFund(deletingFund.id)
                    }
                    deletingFund = nil
                }
                Button("Cancel", role: .cancel) { deletingFund = nil }
            }
        }
    }

    private func showToast(_ text: String) {
        savedToast = text
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if savedToast == text { savedToast = nil }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fareway")
                    .font(FWTheme.titleFont)
                    .foregroundStyle(FWTheme.ink)
                Text("Every trip, one thermometer away")
                    .font(.caption)
                    .foregroundStyle(FWTheme.inkFaded)
            }
            Spacer()
            Button {
                if store.canAddFund(isPro: purchases.isPro) {
                    sheetMode = .add
                } else {
                    sheetMode = .paywall
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(FWTheme.mercuryTop)
            }
            .accessibilityIdentifier("addFundButton")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "thermometer.low")
                .font(.system(size: 34))
                .foregroundStyle(FWTheme.inkFaded)
            Text("No trip funds yet. Tap + to start saving for your next getaway.")
                .font(.subheadline)
                .foregroundStyle(FWTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

private struct TripFundCard: View {
    let fund: TripFund
    let isCelebrating: Bool
    let onLogDeposit: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label(fund.name, systemImage: fund.theme.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FWTheme.ink)
                    .lineLimit(1)
                Spacer()
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Trip", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(FWTheme.inkFaded)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("fundMenu_\(fund.name)")
            }

            ZStack {
                ThermometerView(progress: fund.displayProgress, overfunded: fund.overageAmount > 0)

                if isCelebrating {
                    ConfettiBurstView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            VStack(spacing: 2) {
                Text(fund.currentAmount, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(FWTheme.mercuryTop)
                Text("of \(fund.targetAmount, format: .currency(code: "USD").precision(.fractionLength(0))) goal")
                    .font(.caption2)
                    .foregroundStyle(FWTheme.inkFaded)
                if fund.isGoalReached {
                    Text("Goal reached!")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FWTheme.brass)
                        .accessibilityIdentifier("goalReachedLabel_\(fund.name)")
                }
            }

            Button(action: onLogDeposit) {
                Label("Log Deposit", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(FWTheme.teal)
            .accessibilityIdentifier("logDepositButton_\(fund.name)")
        }
        .padding(14)
        .background(FWTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(FWTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    FundListView()
        .environmentObject(FarewayStore())
        .environmentObject(PurchaseManager())
}
