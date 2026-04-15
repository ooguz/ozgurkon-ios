import Foundation

extension URL {
  /// Set this when the app is published on the App Store.
  static var appStore: URL? {
    nil
  }

  static var sourceCodeRepository: URL? {
    URL(string: "https://github.com/ooguz/ozgurkon-ios")
  }
}
