@testable
import OzgurKon
import XCTest

final class UpdateServiceTests: XCTestCase {
  func testDetectUpdates() {
    let bundleIdentifier = "org.ozgurkon.app"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let result1 = AppStoreSearchResult(bundleIdentifier: "invalid identifier", version: "invalid version")
    let result2 = AppStoreSearchResult(bundleIdentifier: bundleIdentifier, version: "1.1.1")
    let response = AppStoreSearchResponse(results: [result1, result2])
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(response))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertTrue(didDetectUpdates)
  }

  func testDetectUpdatesNoUpdate() {
    let bundleIdentifier = "org.ozgurkon.app"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let result1 = AppStoreSearchResult(bundleIdentifier: bundleIdentifier, version: "1.0.0")
    let result2 = AppStoreSearchResult(bundleIdentifier: "invalid identifier", version: "2.0.0")
    let response = AppStoreSearchResponse(results: [result1, result2])
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(response))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertFalse(didDetectUpdates)
  }

  func testDetectUpdatesAppNotInSearchResults() {
    let bundleIdentifier = "org.ozgurkon.app"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let response = AppStoreSearchResponse(results: [
      AppStoreSearchResult(bundleIdentifier: "com.example.other", version: "99.0.0"),
    ])
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(response))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertFalse(didDetectUpdates)
  }

  func testDetectUpdatesNetworkError() {
    let bundleIdentifier = "org.ozgurkon.app"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let networkServiceError = NSError(domain: "org.ozgurkon.app", code: 1)
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.failure(networkServiceError))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertFalse(didDetectUpdates)
  }
}
