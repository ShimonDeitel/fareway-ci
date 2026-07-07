import XCTest

final class FarewayUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddFundFromMainList() throws {
        let app = launchApp()

        let addButton = app.buttons["addFundButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["fundNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "New Trip Fund sheet did not appear")
        nameField.tap()
        nameField.typeText("Tokyo Trip")

        let targetField = app.textFields["fundTargetField"]
        targetField.tap()
        targetField.typeText("2500")

        let saveButton = app.buttons["fundSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Tokyo Trip"].waitForExistence(timeout: 5), "New trip fund did not appear on the list")
    }

    func testLogDepositUpdatesAmount() throws {
        let app = launchApp()

        let addButton = app.buttons["addFundButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["fundNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Deposit Test Trip")
        let targetField = app.textFields["fundTargetField"]
        targetField.tap()
        targetField.typeText("1000")
        app.buttons["fundSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Deposit Test Trip"].waitForExistence(timeout: 5))

        let depositButton = app.buttons["logDepositButton_Deposit Test Trip"]
        XCTAssertTrue(depositButton.waitForExistence(timeout: 5))
        depositButton.tap()

        let amountField = app.textFields["depositAmountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5), "Log Deposit sheet did not appear")
        amountField.tap()
        amountField.typeText("300")

        let saveButton = app.buttons["depositSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["$300"].waitForExistence(timeout: 5), "Deposit amount did not appear updated on card")
    }

    func testGoalReachedCelebrationAppears() throws {
        let app = launchApp()

        let addButton = app.buttons["addFundButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["fundNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Goal Trip")
        let targetField = app.textFields["fundTargetField"]
        targetField.tap()
        targetField.typeText("100")
        app.buttons["fundSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Goal Trip"].waitForExistence(timeout: 5))

        let depositButton = app.buttons["logDepositButton_Goal Trip"]
        XCTAssertTrue(depositButton.waitForExistence(timeout: 5))
        depositButton.tap()

        let amountField = app.textFields["depositAmountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        amountField.tap()
        amountField.typeText("150")
        app.buttons["depositSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Goal reached!"].waitForExistence(timeout: 5), "Goal-reached label did not appear")
        XCTAssertTrue(app.otherElements["goalCelebrationConfetti"].waitForExistence(timeout: 5), "Confetti celebration did not appear")
    }

    func testKeyboardDismissesOnTapOutsideInAddSheet() throws {
        let app = launchApp()

        let addButton = app.buttons["addFundButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["fundNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5), "Keyboard did not appear after tapping field")

        // Tap a real Form section header label (not nav bar chrome) to
        // trigger dismissKeyboardOnTap's gesture, which is attached to the
        // Form content, not the navigation bar.
        let sectionHeader = app.staticTexts["Theme"]
        XCTAssertTrue(sectionHeader.waitForExistence(timeout: 5))
        sectionHeader.tap()

        let keyboardGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.element, handler: nil)
        wait(for: [keyboardGone], timeout: 5)
    }

    func testPaywallAppearsAtThirdFundOnFreeTier() throws {
        let app = launchApp()
        // Seed data already has 2 funds (free cap), so the very next add attempt must show the paywall.
        let addButton = app.buttons["addFundButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        XCTAssertTrue(app.staticTexts["Fareway Pro"].waitForExistence(timeout: 5), "Paywall did not appear when creating a 3rd trip fund on the free tier")
    }

    func testSettingsOpensAndHasRestorePurchases() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let hapticsToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Haptics'")).firstMatch
        XCTAssertTrue(hapticsToggle.waitForExistence(timeout: 5))
        hapticsToggle.tap()

        let restoreButton = app.buttons["restorePurchasesButton"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5), "Restore Purchases button not present in Settings")
    }
}
