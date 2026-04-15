import Foundation

final class ScheduleService {
  #if DEBUG
  private var isEnabled = true
  #endif

  private var timer: Timer?
  private var isUpdating = false

  private let fosdemYear: Int
  private let timeInterval: TimeInterval
  private let defaults: ScheduleServiceDefaults
  private let networkService: ScheduleServiceNetwork
  private let persistenceService: ScheduleServicePersistence

  init(fosdemYear: Int, networkService: ScheduleServiceNetwork, persistenceService: ScheduleServicePersistence, defaults: ScheduleServiceDefaults = UserDefaults.standard, timeInterval: TimeInterval = 60 * 60) {
    self.defaults = defaults
    self.fosdemYear = fosdemYear
    self.timeInterval = timeInterval
    self.networkService = networkService
    self.persistenceService = persistenceService
  }

  deinit {
    timer?.invalidate()
  }

  func startUpdating() {
    performUpdate(requiresFullInterval: false)
    timer = timer ?? .scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
      self?.performUpdate(requiresFullInterval: true)
    }
  }

  func stopUpdating() {
    timer?.invalidate()
    timer = nil
  }

  private var latestUpdate: Date {
    get { defaults.latestScheduleUpdate ?? .distantPast }
    set { defaults.latestScheduleUpdate = newValue }
  }

  private func performUpdate(requiresFullInterval: Bool) {
    guard !isUpdating else { return }
    let intervalElapsed = abs(latestUpdate.timeIntervalSinceNow) >= timeInterval
    guard !requiresFullInterval || intervalElapsed else { return }

    isUpdating = true

    let request = ScheduleRequest(year: fosdemYear)
    networkService.perform(request) { [weak self] result in
      guard let self else { return }

      switch result {
      case .failure:
        isUpdating = false
        return
      case let .success(schedule):
        #if DEBUG
        guard isEnabled else {
          isUpdating = false
          return
        }
        #endif

        let operation = UpsertSchedule(schedule: schedule)
        persistenceService.performWrite(operation) { [weak self] error in
          assert(error == nil)
          self?.isUpdating = false
          if error == nil {
            self?.latestUpdate = Date()
            DispatchQueue.main.async {
              NotificationCenter.default.post(name: Notification.Name.scheduleDatabaseDidUpdate, object: nil)
            }
          }
        }
      }
    }
  }

  #if DEBUG
  func disable() {
    isEnabled = false
  }
  #endif
}

private extension ScheduleServiceDefaults {
  var latestScheduleUpdate: Date? {
    get { value(forKey: .latestScheduleUpdateKey) as? Date }
    set { set(newValue, forKey: .latestScheduleUpdateKey) }
  }
}

private extension String {
  static var latestScheduleUpdateKey: String { #function }
}

/// @mockable
protocol ScheduleServiceProtocol {
  func startUpdating()
  func stopUpdating()

  #if DEBUG
  func disable()
  #endif
}

extension ScheduleService: ScheduleServiceProtocol {}

/// @mockable
protocol ScheduleServiceDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: ScheduleServiceDefaults {}

/// @mockable
protocol ScheduleServiceNetwork {
  @discardableResult
  func perform(_ request: ScheduleRequest, completion: @escaping (Result<Schedule, Error>) -> Void) -> NetworkServiceTask
}

extension NetworkService: ScheduleServiceNetwork {}

/// @mockable
protocol ScheduleServicePersistence {
  func performWrite(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void)
}

extension PersistenceService: ScheduleServicePersistence {}

protocol HasScheduleService {
  var scheduleService: ScheduleServiceProtocol { get }
}

extension Notification.Name {
  /// Posted on the main queue after Pretalx schedule data is written to the app database.
  static let scheduleDatabaseDidUpdate = Notification.Name("org.ozgurkon.app.scheduleDatabaseDidUpdate")
}
