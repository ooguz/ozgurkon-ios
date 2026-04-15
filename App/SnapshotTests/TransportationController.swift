@testable
import OzgurKon
import SnapshotTesting
import XCTest

final class TransportationControllerTests: XCTestCase {
  struct Dependencies: TransportationController.Dependencies {
    var navigationService: NavigationServiceProtocol = NavigationServiceProtocolMock()
    var openService: OpenServiceProtocol = OpenServiceProtocolMock()
  }

  func testAppearance() {
    let transportationController = TransportationController(dependencies: Dependencies())
    assertSnapshot(matching: transportationController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    var didError: NavigationService.ErrorHandler?
    let infoViewController = UIViewController()

    let openService = OpenServiceProtocolMock()
    openService.openHandler = { _, completion in completion?(true) }

    let navigationService = NavigationServiceProtocolMock()
    navigationService.makeInfoViewControllerHandler = { _, _, receivedDidError in
      didError = receivedDidError
      return infoViewController
    }

    var dependencies = Dependencies()
    dependencies.openService = openService
    dependencies.navigationService = navigationService

    let transportationController = TestTransportationController(dependencies: dependencies)
    assertSnapshot(matching: transportationController, as: .image(on: .iPhone8Plus))

    let transportationViewController = try XCTUnwrap(transportationController.viewControllers.first as? TransportationViewController)

    transportationController.transportationViewController(transportationViewController, didSelect: .appleMaps)
    XCTAssertEqual(openService.openCallCount, 1)
    XCTAssertEqual(openService.openArgValues.last?.absoluteString, "https://maps.apple.com/?q=Bar%C4%B1%C5%9F%20Man%C3%A7o%20K%C3%BClt%C3%BCr%20Merkezi%20Istanbul")

    transportationController.transportationViewController(transportationViewController, didSelect: .googleMaps)
    XCTAssertEqual(openService.openCallCount, 2)
    XCTAssertEqual(openService.openArgValues.last?.absoluteString, "https://www.google.com/maps/search/?api=1&query=Bar%C4%B1%C5%9F%20Man%C3%A7o%20K%C3%BClt%C3%BCr%20Merkezi%20Istanbul")

    transportationController.transportationViewController(transportationViewController, didSelect: .bus)
    XCTAssertEqual(navigationService.makeInfoViewControllerArgValues.map(\.0), ["By bus and/or tram"])
    XCTAssertEqual(navigationService.makeInfoViewControllerArgValues.map(\.1), [.bus])
    XCTAssertEqual(transportationController.showArgValues.map(\.0), [infoViewController])

    didError?(infoViewController, NSError(domain: "test", code: 1))

    XCTAssertEqual(transportationController.popViewControllerArgValues, [true])
  }
}

final class TestTransportationController: TransportationController {
  var showArgValues: [(UIViewController, Any?)] = []
  override func show(_ vc: UIViewController, sender: Any?) {
    super.show(vc, sender: sender)
    showArgValues = [(vc, sender)]
  }

  var popViewControllerArgValues: [Bool] = []
  override func popViewController(animated: Bool) -> UIViewController? {
    popViewControllerArgValues = [animated]
    return super.popViewController(animated: animated)
  }
}
