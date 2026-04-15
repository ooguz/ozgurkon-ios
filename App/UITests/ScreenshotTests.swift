import XCTest

final class ScreenshotTests: XCTestCase {
  func testScreenshots() throws {
    let device = try XCTUnwrap(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"])

    let app = XCUIApplication()
    app.launch()

    let takeScreenshot: (String) -> Void = { name in
      let screenshot = app.screenshot()
      let attachment = XCTAttachment(screenshot: screenshot, quality: .original)
      attachment.lifetime = .keepAlways
      attachment.name = "\(device)_\(name)"
      self.add(attachment)
    }

    runActivity(named: "Search") {
      app.searchButton.tap()
      takeScreenshot("1_search")
    }

    runActivity(named: "Agenda") {
      app.agendaButton.tap()
      Thread.sleep(forTimeInterval: 1) // hide scroll indicator
      takeScreenshot("2_agenda")
    }

    runActivity(named: "More") {
      app.moreButton.tap()
      Thread.sleep(forTimeInterval: 1) // hide scroll indicator
      takeScreenshot("3_more")
    }
  }
}
