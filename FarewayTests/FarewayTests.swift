import XCTest
@testable import Fareway

final class FarewayTests: XCTestCase {

    // MARK: - Progress math

    func testProgressAtZero() {
        let fund = TripFund(name: "Trip", targetAmount: 1000, theme: .beach, deposits: [])
        XCTAssertEqual(fund.currentAmount, 0)
        XCTAssertEqual(fund.displayProgress, 0, accuracy: 0.001)
        XCTAssertFalse(fund.isGoalReached)
    }

    func testProgressPartial() {
        let fund = TripFund(name: "Trip", targetAmount: 1000, theme: .beach,
                             deposits: [Deposit(amount: 250)])
        XCTAssertEqual(fund.currentAmount, 250)
        XCTAssertEqual(fund.displayProgress, 0.25, accuracy: 0.001)
        XCTAssertFalse(fund.isGoalReached)
    }

    func testProgressExactlyOneHundredPercent() {
        let fund = TripFund(name: "Trip", targetAmount: 1000, theme: .beach,
                             deposits: [Deposit(amount: 1000)])
        XCTAssertEqual(fund.displayProgress, 1.0, accuracy: 0.001)
        XCTAssertTrue(fund.isGoalReached)
        XCTAssertEqual(fund.overageAmount, 0, accuracy: 0.001)
    }

    func testProgressOverfundedClampedForDisplayButRealOverageTracked() {
        let fund = TripFund(name: "Trip", targetAmount: 1000, theme: .beach,
                             deposits: [Deposit(amount: 1300)])
        XCTAssertEqual(fund.currentAmount, 1300, accuracy: 0.001)
        XCTAssertEqual(fund.displayProgress, 1.0, accuracy: 0.001, "display fill must clamp at 100%")
        XCTAssertEqual(fund.rawProgress, 1.3, accuracy: 0.001, "raw progress must reflect true overage")
        XCTAssertEqual(fund.overageAmount, 300, accuracy: 0.001)
        XCTAssertTrue(fund.isGoalReached)
    }

    // MARK: - Store: multi-fund add/remove + free-tier cap

    @MainActor
    func testStoreAddFundRespectsFreeLimit() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        XCTAssertTrue(store.addFund(name: "Trip 1", targetAmount: 500, theme: .beach, isPro: false))
        XCTAssertTrue(store.addFund(name: "Trip 2", targetAmount: 500, theme: .city, isPro: false))
        XCTAssertFalse(store.addFund(name: "Trip 3", targetAmount: 500, theme: .mountains, isPro: false), "third fund must be blocked on free tier")
        XCTAssertTrue(store.addFund(name: "Trip 3 Pro", targetAmount: 500, theme: .mountains, isPro: true), "pro must allow a third fund")
        XCTAssertEqual(store.funds.count, 3)
    }

    @MainActor
    func testStoreAddFundRejectsEmptyNameOrZeroTarget() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        XCTAssertFalse(store.addFund(name: "   ", targetAmount: 500, theme: .beach, isPro: false))
        XCTAssertFalse(store.addFund(name: "Valid", targetAmount: 0, theme: .beach, isPro: false))
        XCTAssertEqual(store.funds.count, 0)
    }

    @MainActor
    func testStoreDeleteFundRemovesOnlyThatFund() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        store.addFund(name: "Keep", targetAmount: 500, theme: .beach, isPro: false)
        store.addFund(name: "Remove", targetAmount: 500, theme: .city, isPro: false)
        let toRemove = store.funds.first { $0.name == "Remove" }!
        store.deleteFund(toRemove.id)
        XCTAssertEqual(store.funds.count, 1)
        XCTAssertEqual(store.funds.first?.name, "Keep")
    }

    // MARK: - Deposit logging updates correct fund only

    @MainActor
    func testLogDepositUpdatesOnlyTargetFund() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        store.addFund(name: "A", targetAmount: 1000, theme: .beach, isPro: false)
        store.addFund(name: "B", targetAmount: 1000, theme: .city, isPro: false)
        let fundA = store.funds.first { $0.name == "A" }!
        let fundB = store.funds.first { $0.name == "B" }!

        store.logDeposit(fundID: fundA.id, amount: 200)

        let updatedA = store.funds.first { $0.id == fundA.id }!
        let updatedB = store.funds.first { $0.id == fundB.id }!
        XCTAssertEqual(updatedA.currentAmount, 200, accuracy: 0.001)
        XCTAssertEqual(updatedB.currentAmount, 0, accuracy: 0.001, "deposit must not leak into the other fund")
    }

    @MainActor
    func testLogDepositRejectsZeroOrNegativeAmount() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        store.addFund(name: "A", targetAmount: 1000, theme: .beach, isPro: false)
        let fund = store.funds.first!
        XCTAssertFalse(store.logDeposit(fundID: fund.id, amount: 0))
        XCTAssertFalse(store.logDeposit(fundID: fund.id, amount: -50))
        XCTAssertEqual(store.funds.first!.currentAmount, 0)
    }

    @MainActor
    func testLogDepositReturnsTrueOnlyWhenCrossingGoal() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        store.addFund(name: "A", targetAmount: 100, theme: .beach, isPro: false)
        let fund = store.funds.first!

        let firstResult = store.logDeposit(fundID: fund.id, amount: 60)
        XCTAssertFalse(firstResult, "60/100 should not cross the goal")

        let secondResult = store.logDeposit(fundID: fund.id, amount: 50)
        XCTAssertTrue(secondResult, "110/100 crosses the goal on this deposit")

        let thirdResult = store.logDeposit(fundID: fund.id, amount: 20)
        XCTAssertFalse(thirdResult, "already past goal, should not re-trigger crossing")
    }

    @MainActor
    func testUpdateFundModifiesFields() {
        let store = FarewayStore()
        for f in store.funds { store.deleteFund(f.id) }
        store.addFund(name: "Original", targetAmount: 500, theme: .beach, isPro: false)
        let fund = store.funds[0]
        store.updateFund(fund.id, name: "Renamed", targetAmount: 900, theme: .cruise)
        XCTAssertEqual(store.funds[0].name, "Renamed")
        XCTAssertEqual(store.funds[0].targetAmount, 900, accuracy: 0.001)
        XCTAssertEqual(store.funds[0].theme, .cruise)
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        let store = FarewayStore()
        store.deleteAllData()
        XCTAssertFalse(store.funds.isEmpty)
    }
}
