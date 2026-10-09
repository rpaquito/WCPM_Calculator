import XCTest

final class FlowUITests: XCTestCase {
    func testAddProfileRunTestAndSaveResult() {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "en"]
        app.launch()

        // Options: add a profile
        app.tabBars.buttons["Options"].tap()
        app.buttons["Add profile"].tap()
        let nameField = app.alerts.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.typeText("Ana")
        app.alerts.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Ana"].waitForExistence(timeout: 3))

        // Test: new test, run it
        app.tabBars.buttons["Test"].tap()
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Passage 1")
        app.textFields["Words"].tap()
        app.textFields["Words"].typeText("100")
        app.buttons["Start test"].tap()

        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 3))
        start.tap()
        sleep(2)
        app.buttons["Stop"].tap()

        // Enter wrong words and save
        let wrong = app.textFields["wrongWords"]
        XCTAssertTrue(wrong.waitForExistence(timeout: 3))
        wrong.tap()
        wrong.typeText("5")
        XCTAssertFalse(app.staticTexts["–"].exists)
        app.buttons["Save"].tap()

        // Back on setup with the new test selected (redo ready)
        XCTAssertTrue(app.buttons["Start test"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Passage 1"].exists || app.buttons["Passage 1"].exists)
    

        // Results: test listed, history has one entry, swipe-delete removes it
        app.tabBars.buttons["Results"].tap()
        let row = app.cells.containing(.staticText, identifier: "Passage 1").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
        XCTAssertTrue(app.staticTexts["Progress"].waitForExistence(timeout: 3))
        let entries = app.cells.containing(NSPredicate(format: "label CONTAINS 'wrong'"))
        XCTAssertEqual(entries.count, 1)
        entries.firstMatch.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertEqual(entries.count, 0)
    }
}
