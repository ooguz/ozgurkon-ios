import Foundation

struct ScheduleRequest: NetworkRequest {
  enum Error: CustomNSError, Equatable {
    case notFound
    case invalidSchedule
  }

  let year: Int

  var url: URL {
    PretalxConfiguration.scheduleExportURL
  }

  func decode(_ data: Data?, response: HTTPURLResponse?) throws -> Schedule {
    guard year == PretalxConfiguration.supportedYear else {
      throw Error.notFound
    }
    guard let data, response?.statusCode != 404 else {
      throw Error.notFound
    }

    let xmlParser = ScheduleXMLParser(data: data)
    guard xmlParser.parse(), let schedule = xmlParser.schedule else {
      throw Error.invalidSchedule
    }
    return schedule
  }
}
