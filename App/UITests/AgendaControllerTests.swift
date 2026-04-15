import XCTest

/// Agenda UI tests previously depended on a bundled FOSDEM schedule. Use lightweight checks against the ÖzgürKon product.
final class AgendaControllerTests: XCTestCase {
  func testAgendaTabShowsTitle() {
    let app = XCUIApplication()
    app.launch()
    app.agendaButton.tap()
    XCTAssertTrue(app.navigationBars["Agenda"].waitForExistence(timeout: 5))
  }
}
