import XCTest

final class EventControllerTests: XCTestCase {
  func testFavoriteFirstEvent() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()

    app.searchButton.tap()
    XCTAssertTrue(app.firstTrackCell.waitForExistence(timeout: 5))
    app.firstTrackCell.tap()
    XCTAssertTrue(app.firstTrackEventCell.waitForExistence(timeout: 5))
    app.firstTrackEventCell.tap()

    app.favoriteEventButton.tap()
    XCTAssertTrue(app.unfavoriteEventButton.exists)
  }
}

extension XCUIApplication {
  var eventTable: XCUIElement {
    tables["event"]
  }

  var favoriteEventButton: XCUIElement {
    buttons["favorite"]
  }

  var unfavoriteEventButton: XCUIElement {
    buttons["unfavorite"]
  }
}
