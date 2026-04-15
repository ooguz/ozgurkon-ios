import XCTest

final class YearControllerTests: XCTestCase {
  func testConferenceEditionRow() {
    let app = XCUIApplication()
    app.launch()
    app.moreButton.tap()
    app.yearsCell.tap()
    XCTAssertTrue(app.cells["2026"].waitForExistence(timeout: 5))
  }
}

private extension XCUIApplication {
  var yearsCell: XCUIElement {
    cells["years"]
  }
}
