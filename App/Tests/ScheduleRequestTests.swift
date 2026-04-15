@testable
import OzgurKon
import XCTest

final class ScheduleRequestTests: XCTestCase {
  func testDecode() throws {
    let data = try BundleDataLoader().data(forResource: "ozgurkon-2026", withExtension: "xml")

    let requestURL = URL(string: "https://cfp.oyd.org.tr/ozgurkon-2026/schedule/export/schedule.xml")
    let request = ScheduleRequest(year: 2026)
    XCTAssertEqual(request.url, requestURL)

    let schedule = try request.decode(data, response: nil)
    XCTAssertEqual(schedule.conference.title, "ÖzgürKon 2026")
    XCTAssertEqual(schedule.conference.venue, PretalxConfiguration.defaultVenue)
    XCTAssertEqual(schedule.conference.city, PretalxConfiguration.defaultCity)
    XCTAssertEqual(schedule.days.count, 1)
    XCTAssertEqual(schedule.days[0].events.count, 1)
    XCTAssertEqual(schedule.days[0].events[0].id, 1)
    XCTAssertEqual(schedule.days[0].events[0].people.count, 1)
    XCTAssertTrue(schedule.days[0].events[0].links.contains { $0.name == "Feedback" })
  }

  func testWrongYearNotFound() {
    let request = ScheduleRequest(year: 2020)
    let data = "{}".data(using: .utf8)!
    XCTAssertThrowsError(try request.decode(data, response: nil)) { error in
      XCTAssertEqual(error as? ScheduleRequest.Error, .notFound)
    }
  }

  func testNotFound() {
    let request = ScheduleRequest(year: 2026)
    let response = HTTPURLResponse(url: request.url, statusCode: 404, httpVersion: nil, headerFields: nil)
    XCTAssertThrowsError(try request.decode(Data(), response: response)) { error in
      XCTAssertEqual(error as? ScheduleRequest.Error, .notFound)
    }
  }
}
