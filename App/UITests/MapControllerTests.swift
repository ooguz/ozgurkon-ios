import XCTest

/// The Map tab is not included in ÖzgürKon v1; keep lightweight coverage that the tab bar matches the product.
final class MapControllerTests: XCTestCase {
  func testMapTabHidden() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertFalse(app.tabBars.buttons["map"].exists)
  }
}

extension XCUIApplication {
  var mapButton: XCUIElement {
    tabBars.buttons["map"]
  }

  var buildingView: XCUIElement {
    buildingView(forIdentifier: "K")
  }

  var niceBuildingView: XCUIElement {
    buildingView(forIdentifier: "U")
  }

  var blueprintsContainer: XCUIElement {
    otherElements["embedded_blueprints"]
  }

  var blueprintsFullscreenDismissButton: XCUIElement {
    buttons["fullscreen_dismiss"]
  }
}

private extension XCUIApplication {
  var noBlueprintBuildingView: XCUIElement {
    buildingView(forIdentifier: "F")
  }

  var pageIndicator: XCUIElement {
    pageIndicators.firstMatch
  }

  var areAllBuildingsVisibile: Bool {
    for identifier in ["AW", "F", "J", "H", "U", "K", "S"] {
      if !buildingView(forIdentifier: identifier).exists {
        return false
      }
    }
    return true
  }

  func buildingView(forIdentifier identifier: String) -> XCUIElement {
    otherElements["building_\(identifier)"]
  }
}
