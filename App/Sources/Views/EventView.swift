import UIKit

protocol EventViewDelegate: AnyObject {
  func eventViewDidTapLivestream(_ eventView: EventView)
  func eventViewDidTapTrack(_ eventView: EventView)
  func eventViewDidTapVideo(_ eventView: EventView)
  func eventView(_ eventView: EventView, didSelect url: URL)
}

protocol EventViewDataSource: AnyObject {
  func eventView(_ eventView: EventView, playbackPositionFor event: Event) -> PlaybackPosition
}

final class EventView: UIStackView {
  typealias Dependencies = HasDateFormattingService

  weak var delegate: EventViewDelegate?
  weak var dataSource: EventViewDataSource? {
    didSet { reloadPlaybackPosition() }
  }

  var dependencies: Dependencies?
  private var observer: NSObjectProtocol?
  private weak var scheduleClockAttributeView: EventAttributeView?
  private weak var scheduleDurationAttributeView: EventAttributeView?
  private weak var livestreamButton: UIButton?
  private weak var trackAttributeView: EventAttributeView?
  private weak var videoButton: UIButton?

  var event: Event? {
    didSet { didChangeEvent() }
  }

  var allowsTrackSelection = true {
    didSet { didChangeAllowsTrackSelection() }
  }

  var showsLivestream = false {
    didSet { didChangeShowLivestream() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    spacing = 16
    axis = .vertical
    alignment = .leading
  }

  @available(*, unavailable)
  required init(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func reloadPlaybackPosition() {
    var position: PlaybackPosition = .beginning
    if let dataSource, let event {
      position = dataSource.eventView(self, playbackPositionFor: event)
    }

    videoButton?.setTitle(position.title, for: .normal)
    videoButton?.accessibilityLabel = position.accessibilityLabel
    videoButton?.accessibilityIdentifier = position.accessibilityIdentifier
  }

  private func didChangeEvent() {
    if let observer, let formatting = dependencies?.dateFormattingService {
      formatting.removeObserverForFormattingTimeZoneChanges(observer)
    }
    observer = nil
    scheduleClockAttributeView = nil
    scheduleDurationAttributeView = nil

    for subview in arrangedSubviews {
      removeArrangedSubview(subview)
      subview.removeFromSuperview()
    }

    guard let event else { return }

    var constraints: [NSLayoutConstraint] = []

    let titleLabel = UILabel()
    titleLabel.accessibilityTraits = .header
    titleLabel.font = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.accessibilityTraits = .header
    titleLabel.text = event.title
    titleLabel.numberOfLines = 0
    addArrangedSubview(titleLabel)

    if event.video != nil {
      let videoAction = #selector(didTapVideo)
      let videoButton = UIButton.fos_rounded()
      videoButton.accessibilityLabel = L10n.Event.Video.Accessibility.begin
      videoButton.addTarget(self, action: videoAction, for: .touchUpInside)
      videoButton.titleLabel?.adjustsFontForContentSizeCategory = true
      self.videoButton = videoButton
      addArrangedSubview(videoButton)
      setCustomSpacing(20, after: videoButton)

      constraints.append(videoButton.widthAnchor.constraint(equalTo: widthAnchor))

      reloadPlaybackPosition()
    } else if showsLivestream {
      let livestreamAction = #selector(didTapLivestream)
      let livestreamButton = UIButton.fos_rounded()
      livestreamButton.accessibilityIdentifier = "livestream"
      livestreamButton.titleLabel?.adjustsFontForContentSizeCategory = true
      livestreamButton.addTarget(self, action: livestreamAction, for: .touchUpInside)
      livestreamButton.setTitle(L10n.Event.livestream, for: .normal)
      self.livestreamButton = livestreamButton
      addArrangedSubview(livestreamButton)
      setCustomSpacing(20, after: livestreamButton)

      constraints.append(livestreamButton.widthAnchor.constraint(equalTo: widthAnchor))
    }

    let attributesView = EventAttributesView()
    addArrangedSubview(attributesView)
    setCustomSpacing(20, after: attributesView)
    constraints.append(contentsOf: [
      attributesView.widthAnchor.constraint(equalTo: widthAnchor),
    ])

    let configuration = UIImage.SymbolConfiguration(
      font: UIFont.fos_preferredFont(forTextStyle: .title2)
    )

    if let deps = dependencies {
      let dateTime = deps.dateFormattingService.eventScheduleDateTime(from: event.date)
      let durationPhrase = DurationFormatter().duration(from: event.duration).map { L10n.Event.duration($0) }
      let maxLabelWidth = scheduleAttributesMaxLabelWidth()
      let combinedForMeasure = durationPhrase.map { "\(dateTime) (\($0))" }
      let shouldSplitDuration = combinedForMeasure.map { !eventScheduleFitsSingleLine($0, maxWidth: maxLabelWidth) } ?? false

      let clockView = EventAttributeView()
      clockView.image = .init(systemName: "clock.circle.fill", withConfiguration: configuration)

      if shouldSplitDuration, let phrase = durationPhrase {
        clockView.text = dateTime
        clockView.accessibilityLabel = dateTime

        let durationView = EventAttributeView()
        durationView.image = .init(systemName: "stopwatch", withConfiguration: configuration)
        durationView.text = phrase
        durationView.accessibilityLabel = phrase

        attributesView.addArrangedSubview(clockView)
        attributesView.addArrangedSubview(durationView)
        scheduleClockAttributeView = clockView
        scheduleDurationAttributeView = durationView
      } else if let phrase = durationPhrase {
        let combined = "\(dateTime) (\(phrase))"
        clockView.text = combined
        clockView.accessibilityLabel = combined
        attributesView.addArrangedSubview(clockView)
        scheduleClockAttributeView = clockView
      } else {
        clockView.text = dateTime
        clockView.accessibilityLabel = dateTime
        attributesView.addArrangedSubview(clockView)
        scheduleClockAttributeView = clockView
      }

      observer = deps.dateFormattingService.addObserverForFormattingTimeZoneChanges { [weak self] in
        self?.updateScheduleAttributeLabels(for: event)
      }
    }

    let roomAttributeView = EventAttributeView()
    roomAttributeView.accessibilityLabel = L10n.Event.room
    roomAttributeView.accessibilityValue = event.room
    roomAttributeView.text = event.room
    roomAttributeView.image = .init(systemName: "mappin.circle.fill", withConfiguration: configuration)
    attributesView.addArrangedSubview(roomAttributeView)

    if !event.people.isEmpty {
      let people = PeopleFormatter().formattedPeople(from: event.people)
      let attributeView = EventAttributeView()
      attributeView.accessibilityLabel = L10n.Event.people
      attributeView.accessibilityValue = people
      attributeView.text = people
      attributeView.image = .init(systemName: "person.circle.fill", withConfiguration: configuration)
      attributesView.addArrangedSubview(attributeView)
    }

    let track = TrackFormatter().formattedName(from: event.track)
    let trackAttributeView = EventAttributeView()
    trackAttributeView.accessibilityLabel = L10n.Event.track
    trackAttributeView.accessibilityValue = track
    trackAttributeView.text = track
    trackAttributeView.image = .init(systemName: "grid.circle.fill", withConfiguration: configuration)
    trackAttributeView.addTarget(self, action: #selector(didTapTrack), for: .touchUpInside)
    self.trackAttributeView = trackAttributeView
    attributesView.addArrangedSubview(trackAttributeView)

    if let summary = event.summary {
      let separatorView = UIView()
      separatorView.backgroundColor = .separator
      addArrangedSubview(separatorView)
      constraints.append(contentsOf: [
        separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        separatorView.widthAnchor.constraint(equalTo: widthAnchor),
      ])

      let summary = SummaryFormatter().formattedSummary(from: summary)
      let summaryLabel = UILabel()
      summaryLabel.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitItalic)
      summaryLabel.adjustsFontForContentSizeCategory = true
      summaryLabel.numberOfLines = 0
      summaryLabel.text = summary
      addArrangedSubview(summaryLabel)
    }

    if let abstract = event.abstract, let abstractNode = HTMLParser().parse(abstract), let attributedAbstract = HTMLRenderer().render(abstractNode) {
      let separatorView = UIView()
      separatorView.backgroundColor = .separator
      addArrangedSubview(separatorView)
      constraints.append(contentsOf: [
        separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        separatorView.widthAnchor.constraint(equalTo: widthAnchor),
      ])

      let subtitleLabel = UILabel()
      subtitleLabel.accessibilityTraits = .header
      subtitleLabel.font = .fos_preferredFont(forTextStyle: .headline)
      subtitleLabel.adjustsFontForContentSizeCategory = true
      subtitleLabel.numberOfLines = 0
      subtitleLabel.text = event.subtitle ?? L10n.Event.abstract
      addArrangedSubview(subtitleLabel)

      let abstractView = UITextView()
      abstractView.backgroundColor = .clear
      abstractView.isScrollEnabled = false
      abstractView.isEditable = false
      abstractView.textContainer.lineFragmentPadding = 0
      abstractView.adjustsFontForContentSizeCategory = true
      abstractView.attributedText = attributedAbstract
      addArrangedSubview(abstractView)
    }

    let groups: [EventAdditionsGroup] = [
      .init(links: event.links),
      .init(attachments: event.attachments),
    ]

    if !groups.allSatisfy(\.items.isEmpty) {
      let separatorView = UIView()
      separatorView.backgroundColor = .separator
      addArrangedSubview(separatorView)
      constraints.append(contentsOf: [
        separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        separatorView.widthAnchor.constraint(equalTo: widthAnchor),
      ])
    }

    for group in groups {
      if !group.items.isEmpty {
        let groupLabel = UILabel()
        groupLabel.accessibilityTraits = .header
        groupLabel.font = .fos_preferredFont(forTextStyle: .headline)
        groupLabel.text = group.title
        groupLabel.adjustsFontForContentSizeCategory = true
        groupLabel.numberOfLines = 0
        addArrangedSubview(groupLabel)
      }

      for item in group.items {
        let itemAction = #selector(didTapAdditionalItem(_:))
        let itemView = EventAdditionsItemView()
        itemView.item = item
        itemView.group = group
        itemView.addTarget(self, action: itemAction, for: .touchUpInside)
        addArrangedSubview(itemView)

        constraints.append(itemView.widthAnchor.constraint(equalTo: widthAnchor))
      }
    }

    accessibilityElements = subviews

    NSLayoutConstraint.activate(constraints)

    didChangeAllowsTrackSelection()
    didChangeShowLivestream()
  }

  private func didChangeShowLivestream() {
    livestreamButton?.isHidden = !showsLivestream
  }

  private func didChangeAllowsTrackSelection() {
    let action = #selector(didTapTrack)
    if allowsTrackSelection {
      trackAttributeView?.addTarget(self, action: action, for: .touchUpInside)
    } else {
      trackAttributeView?.removeTarget(self, action: action, for: .touchUpInside)
    }
  }

  @objc private func didTapLivestream() {
    delegate?.eventViewDidTapLivestream(self)
  }

  @objc private func didTapTrack() {
    delegate?.eventViewDidTapTrack(self)
  }

  @objc private func didTapVideo() {
    delegate?.eventViewDidTapVideo(self)
  }

  @objc private func didTapAdditionalItem(_ itemView: EventAdditionsItemView) {
    if let item = itemView.item {
      delegate?.eventView(self, didSelect: item.url)
    }
  }

  private func scheduleAttributesMaxLabelWidth() -> CGFloat {
    let screenWidth = window?.bounds.width ?? UIScreen.main.bounds.width
    let containerWidth = bounds.width > 10 ? bounds.width : screenWidth
    // EventAttributesView horizontal insets (16+16) and icon column (~34) + spacing (10).
    return max(80, containerWidth - 32 - 44)
  }

  private func eventScheduleFitsSingleLine(_ text: String, maxWidth: CGFloat) -> Bool {
    let font = UIFont.fos_preferredFont(forTextStyle: .body)
    let size = (text as NSString).boundingRect(
      with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    return size.height <= font.lineHeight * 1.25
  }

  private func updateScheduleAttributeLabels(for event: Event) {
    guard let deps = dependencies else { return }
    let dateTime = deps.dateFormattingService.eventScheduleDateTime(from: event.date)
    let durationPhrase = DurationFormatter().duration(from: event.duration).map { L10n.Event.duration($0) }

    if scheduleDurationAttributeView != nil {
      scheduleClockAttributeView?.text = dateTime
      scheduleClockAttributeView?.accessibilityLabel = dateTime
      if let phrase = durationPhrase {
        scheduleDurationAttributeView?.text = phrase
        scheduleDurationAttributeView?.accessibilityLabel = phrase
      }
    } else if let phrase = durationPhrase {
      let combined = "\(dateTime) (\(phrase))"
      scheduleClockAttributeView?.text = combined
      scheduleClockAttributeView?.accessibilityLabel = combined
    } else {
      scheduleClockAttributeView?.text = dateTime
      scheduleClockAttributeView?.accessibilityLabel = dateTime
    }
  }
}

private extension PlaybackPosition {
  var title: String {
    switch self {
    case .beginning: L10n.Event.Video.begin
    case .end: L10n.Event.Video.end
    case .at: L10n.Event.Video.at
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .beginning: L10n.Event.Video.Accessibility.begin
    case .end: L10n.Event.Video.Accessibility.end
    case .at: L10n.Event.Video.Accessibility.at
    }
  }

  var accessibilityIdentifier: String {
    switch self {
    case .beginning: "play"
    case .end: "replay"
    case .at: "resume"
    }
  }
}
