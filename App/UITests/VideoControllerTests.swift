import XCTest

final class VideoControllerTests: XCTestCase {
  func testMoreVideosScreenOpens() {
    let app = XCUIApplication()
    app.launch()
    app.moreButton.tap()
    app.cells["video"].tap()
    XCTAssertTrue(app.navigationBars["Videos"].waitForExistence(timeout: 5))
  }
}
