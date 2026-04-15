import Foundation

enum PretalxConfiguration {
  static let baseURL = URL(string: "https://cfp.oyd.org.tr")!
  static let eventSlug = "ozgurkon-2026"
  static let supportedYear = 2026

  static var scheduleExportURL: URL {
    baseURL.appendingPathComponent(eventSlug).appendingPathComponent("schedule/export/schedule.xml")
  }

  static let defaultVenue = "Barış Manço Kültür Merkezi"
  static let defaultCity = "Istanbul"
}
