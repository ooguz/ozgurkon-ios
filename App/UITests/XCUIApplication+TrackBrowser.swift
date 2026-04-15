import XCTest

extension XCUIApplication {
  var searchButton: XCUIElement {
    tabBars.buttons["search"]
  }

  var agendaButton: XCUIElement {
    tabBars.buttons["agenda"]
  }

  /// Events table shown after selecting a track.
  var trackTable: XCUIElement {
    tables["events"]
  }

  /// First row in the tracks list on the Search tab.
  var firstTrackCell: XCUIElement {
    tables["tracks"].cells.element(boundBy: 0)
  }

  /// First row in the events list when browsing a track.
  var firstTrackEventCell: XCUIElement {
    tables["events"].cells.element(boundBy: 0)
  }
}
