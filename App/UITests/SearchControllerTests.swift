import XCTest

/// Full search/track flows previously targeted FOSDEM fixture data. Smoke-test the Search tab for ÖzgürKon.
final class SearchControllerTests: XCTestCase {
  func testSearchTabShowsTitle() {
    let app = XCUIApplication()
    app.launch()
    app.searchButton.tap()
    XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 5))
  }
}
