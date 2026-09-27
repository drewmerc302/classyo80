import XCTest

final class ClassyO80UITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testOnePlusTwoEqualsThree() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        for identifier in ["key.1", "key.plus", "key.2", "key.equals"] {
            let key = app.buttons[identifier]
            XCTAssertTrue(key.waitForExistence(timeout: 5), "\(identifier) is missing")
            key.tap()
        }

        let lcd = app.descendants(matching: .any)["lcd"]
        XCTAssertTrue(lcd.waitForExistence(timeout: 5))
        XCTAssertEqual(lcd.value as? String, "3")
    }
}
