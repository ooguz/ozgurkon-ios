import UIKit

class TransportationController: UINavigationController {
  typealias Dependencies = HasNavigationService & HasOpenService

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)

    let style = traitCollection.userInterfaceIdiom == .phone ? UITableView.Style.insetGrouped : .fos_grouped
    let transportationViewController = TransportationViewController(style: style)
    transportationViewController.title = L10n.Transportation.title
    transportationViewController.delegate = self
    viewControllers = [transportationViewController]
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TransportationController: TransportationViewControllerDelegate {
  func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationItem) {
    switch item {
    case .appleMaps:
      self.transportationViewController(transportationViewController, didSelect: .venueAppleMaps)
    case .googleMaps:
      self.transportationViewController(transportationViewController, didSelect: .venueGoogleMaps)
    case .bus, .car, .taxi, .plane, .train:
      if let info = item.info {
        self.transportationViewController(transportationViewController, didSelect: item, info: info)
      } else {
        assertionFailure("Failed to determine info model for transportation item '\(item)'")
      }
    }
  }

  private func transportationViewController(_ transportationViewController: TransportationViewController, didSelect directionsURL: URL) {
    dependencies.openService.open(directionsURL) { [weak transportationViewController] _ in
      transportationViewController?.deselectSelectedRow(animated: true)
    }
  }

  private func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationItem, info: Info) {
    let infoViewController = dependencies.navigationService.makeInfoViewController(for: info)
    infoViewController.navigationItem.largeTitleDisplayMode = traitCollection.userInterfaceIdiom == .phone ? .never : .always
    infoViewController.accessibilityIdentifier = info.accessibilityIdentifier
    infoViewController.title = item.title
    infoViewController.load { error in
      if error != nil {
        let errorViewController = UIAlertController.makeErrorController()
        transportationViewController.present(errorViewController, animated: true)
      } else {
        transportationViewController.show(infoViewController, sender: nil)
      }
    }
  }
}

private extension URL {
  static let venueAppleMaps = URL(string: "https://maps.apple.com/?q=Bar%C4%B1%C5%9F%20Man%C3%A7o%20K%C3%BClt%C3%BCr%20Merkezi%20Istanbul")!
  static let venueGoogleMaps = URL(string: "https://www.google.com/maps/search/?api=1&query=Bar%C4%B1%C5%9F%20Man%C3%A7o%20K%C3%BClt%C3%BCr%20Merkezi%20Istanbul")!
}
