import XCTest

final class PapamooUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddMenuShowsCameraAndDirectEntryActions() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["home.add-menu"].tap()

        XCTAssertTrue(app.buttons["home.add-camera"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["home.add-pencil"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home Add Menu"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
