import Foundation

/// @mockable
protocol PreloadServiceFile {
  func fileExists(atPath path: String) -> Bool
  func copyItem(atPath srcPath: String, toPath dstPath: String) throws
  func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL
  func removeItem(atPath path: String) throws
  @discardableResult
  func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool
}

/// @mockable
protocol PreloadServiceBundle {
  func path(forResource name: String?, ofType ext: String?) -> String?
}

final class PreloadService {
  enum Error: CustomNSError {
    case couldNotCreateEmptyDatabase
  }

  private let bundledTemplatePath: String?
  private let newPath: String
  private let fileManager: PreloadServiceFile

  init(bundle: PreloadServiceBundle = Bundle.main, fileManager: PreloadServiceFile = FileManager.default) throws {
    self.fileManager = fileManager

    let fileName = "db", fileExtension = "sqlite"
    bundledTemplatePath = bundle.path(forResource: fileName, ofType: fileExtension)

    let applicationSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let applicationDatabaseURL = applicationSupportURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
    newPath = applicationDatabaseURL.path
  }

  var databasePath: String {
    newPath
  }

  func removeDatabase() throws {
    try fileManager.removeItem(atPath: newPath)
  }

  func preloadDatabaseIfNeeded() throws {
    if !fileManager.fileExists(atPath: newPath) {
      if let bundledTemplatePath {
        try fileManager.copyItem(atPath: bundledTemplatePath, toPath: newPath)
      } else {
        guard fileManager.createFile(atPath: newPath, contents: nil, attributes: nil) else {
          throw Error.couldNotCreateEmptyDatabase
        }
      }
    }
  }
}

extension Bundle: PreloadServiceBundle {}

extension FileManager: PreloadServiceFile {}
