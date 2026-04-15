import Foundation

final class UpdateService {
  private let bundle: UpdateServiceBundle
  private let networkService: UpdateServiceNetwork

  init(networkService: UpdateServiceNetwork, bundle: UpdateServiceBundle = Bundle.main) {
    self.networkService = networkService
    self.bundle = bundle
  }

  func detectUpdates(completion: @escaping () -> Void) {
    guard let bundleIdentifier = bundle.bundleIdentifier else {
      return assertionFailure("Failed to acquire bundle identifier from bundle \(bundle)")
    }

    guard let bundleShortVersion = bundle.bundleShortVersion else {
      return assertionFailure("Failed to acquire short bundle version from bundle \(bundle)")
    }

    let request = AppStoreSearchRequest()
    networkService.perform(request) { result in
      guard case let .success(response) = result else { return }

      // Until the app is live, iTunes search may omit this bundle id; treat as no update.
      guard let result = response.results.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        return
      }

      if result.version.compare(bundleShortVersion, options: .numeric) == .orderedDescending {
        completion()
      }
    }
  }
}

/// @mockable
protocol UpdateServiceProtocol: AnyObject {
  func detectUpdates(completion: @escaping () -> Void)
}

extension UpdateService: UpdateServiceProtocol {}

/// @mockable
protocol UpdateServiceBundle {
  var bundleIdentifier: String? { get }
  var bundleShortVersion: String? { get }
}

extension Bundle: UpdateServiceBundle {}

/// @mockable
protocol UpdateServiceNetwork {
  @discardableResult
  func perform(_ request: AppStoreSearchRequest, completion: @escaping (Result<AppStoreSearchResponse, Error>) -> Void) -> NetworkServiceTask
}

extension NetworkService: UpdateServiceNetwork {}

protocol HasUpdateService {
  var updateService: UpdateServiceProtocol { get }
}
