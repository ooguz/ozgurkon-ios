import Foundation

final class LaunchService {
  enum Error: CustomNSError {
    case versionDetectionFailed
  }

  static let latestConferenceYearKey = "org.ozgurkon.app.LATEST_CONFERENCE_YEAR"
  static let latestBundleShortVersionKey = "LATEST_BUNDLE_SHORT_VERSION"

  private(set) var didLaunchAfterUpdate = false
  private(set) var didLaunchAfterInstall = false
  private(set) var didLaunchAfterConferenceYearChange = false

  private let conferenceYear: Year
  private let bundle: LaunchServiceBundle
  private let defaults: LaunchServiceDefaults

  init(fosdemYear: Year, bundle: LaunchServiceBundle = Bundle.main, defaults: LaunchServiceDefaults = UserDefaults.standard) {
    self.bundle = bundle
    self.defaults = defaults
    conferenceYear = fosdemYear
  }

  func detectStatus() throws {
    guard let bundleShortVersion = bundle.bundleShortVersion else {
      throw Error.versionDetectionFailed
    }

    switch defaults.latestBundleShortVersion {
    case .some(bundleShortVersion):
      didLaunchAfterUpdate = false
      didLaunchAfterInstall = false
    case .some:
      didLaunchAfterUpdate = true
      didLaunchAfterInstall = false
    case nil:
      didLaunchAfterUpdate = false
      didLaunchAfterInstall = true
    }

    didLaunchAfterConferenceYearChange = !didLaunchAfterInstall && defaults.latestConferenceYear != conferenceYear

    defaults.latestConferenceYear = conferenceYear
    defaults.latestBundleShortVersion = bundleShortVersion
  }

  #if DEBUG
  func markAsLaunched() {
    defaults.latestConferenceYear = conferenceYear
    defaults.latestBundleShortVersion = bundle.bundleShortVersion
  }
  #endif
}

extension LaunchServiceDefaults {
  var latestConferenceYear: Int? {
    get { string(forKey: LaunchService.latestConferenceYearKey).flatMap { string in Int(string) } }
    set { set(newValue?.description, forKey: LaunchService.latestConferenceYearKey) }
  }

  var latestBundleShortVersion: String? {
    get { string(forKey: LaunchService.latestBundleShortVersionKey) }
    set { set(newValue, forKey: LaunchService.latestBundleShortVersionKey) }
  }
}

/// @mockable
protocol LaunchServiceProtocol {
  var didLaunchAfterUpdate: Bool { get }
  var didLaunchAfterInstall: Bool { get }
  var didLaunchAfterConferenceYearChange: Bool { get }

  func detectStatus() throws
  #if DEBUG
  func markAsLaunched()
  #endif
}

extension LaunchService: LaunchServiceProtocol {}

protocol LaunchServiceBundle {
  var bundleShortVersion: String? { get }
}

extension Bundle: LaunchServiceBundle {}

protocol LaunchServiceDefaults: AnyObject {
  func string(forKey key: String) -> String?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: LaunchServiceDefaults {}

protocol HasLaunchService {
  var launchService: LaunchServiceProtocol { get }
}
