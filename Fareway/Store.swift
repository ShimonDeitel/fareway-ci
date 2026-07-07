import Foundation

@MainActor
final class FarewayStore: ObservableObject {
    @Published private(set) var funds: [TripFund] = []

    static let freeFundLimit = 2

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("fareway_funds.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if funds.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        funds = [
            TripFund(name: "Lisbon Getaway", targetAmount: 2000, theme: .city,
                     createdDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
                     deposits: [Deposit(amount: 350, date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, note: "First deposit")]),
            TripFund(name: "Maui Beach Week", targetAmount: 3500, theme: .beach,
                     createdDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                     deposits: [Deposit(amount: 600, date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, note: "")])
        ]
        save()
    }

    func canAddFund(isPro: Bool) -> Bool {
        isPro || funds.count < Self.freeFundLimit
    }

    @discardableResult
    func addFund(name: String, targetAmount: Double, theme: TripTheme, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, targetAmount > 0, canAddFund(isPro: isPro) else { return false }
        let fund = TripFund(name: trimmed, targetAmount: targetAmount, theme: theme)
        funds.append(fund)
        save()
        return true
    }

    func updateFund(_ id: UUID, name: String, targetAmount: Double, theme: TripTheme) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, targetAmount > 0, let idx = funds.firstIndex(where: { $0.id == id }) else { return }
        funds[idx].name = trimmed
        funds[idx].targetAmount = targetAmount
        funds[idx].theme = theme
        save()
    }

    func deleteFund(_ id: UUID) {
        funds.removeAll { $0.id == id }
        save()
    }

    /// Appends a deposit to exactly the fund matching `fundID` and re-persists.
    /// Returns true if the deposit crossed the fund from under-goal to goal-reached,
    /// so the caller can trigger the celebration animation.
    @discardableResult
    func logDeposit(fundID: UUID, amount: Double, date: Date = Date(), note: String = "") -> Bool {
        guard amount > 0, let idx = funds.firstIndex(where: { $0.id == fundID }) else { return false }
        let wasReached = funds[idx].isGoalReached
        funds[idx].deposits.append(Deposit(amount: amount, date: date, note: note))
        save()
        return !wasReached && funds[idx].isGoalReached
    }

    func deleteAllData() {
        funds = []
        seedDefaults()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var funds: [TripFund]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            funds = decoded.funds
        }
    }

    private func save() {
        let snapshot = Snapshot(funds: funds)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
