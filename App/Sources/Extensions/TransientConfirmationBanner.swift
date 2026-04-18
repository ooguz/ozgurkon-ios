import UIKit

enum TransientConfirmationBanner {
  private static let viewTag = 2_948_221

  /// Brief confirmation the user can see without dismissing an alert (e.g. session added to agenda).
  static func show(on host: UIViewController, message: String, duration: TimeInterval = 2.0) {
    host.view.viewWithTag(viewTag)?.removeFromSuperview()

    let feedback = UINotificationFeedbackGenerator()
    feedback.prepare()
    feedback.notificationOccurred(.success)

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    blur.tag = viewTag
    blur.layer.cornerRadius = 12
    blur.clipsToBounds = true
    blur.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.text = message
    label.font = .fos_preferredFont(forTextStyle: .subheadline)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = .label
    label.adjustsFontForContentSizeCategory = true
    label.translatesAutoresizingMaskIntoConstraints = false

    blur.contentView.addSubview(label)
    host.view.addSubview(blur)

    let padding: CGFloat = 12
    NSLayoutConstraint.activate([
      blur.centerXAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.centerXAnchor),
      blur.bottomAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
      blur.leadingAnchor.constraint(greaterThanOrEqualTo: host.view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      blur.trailingAnchor.constraint(lessThanOrEqualTo: host.view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

      label.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: padding),
      label.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -padding),
      label.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: padding),
      label.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -padding),
    ])

    blur.alpha = 0
    UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
      blur.alpha = 1
    }

    UIAccessibility.post(notification: .announcement, argument: message)

    DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak blur] in
      guard let blur else { return }
      UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
        blur.alpha = 0
      } completion: { _ in
        blur.removeFromSuperview()
      }
    }
  }
}

extension UIViewController {
  func showTransientConfirmationBanner(_ message: String, duration: TimeInterval = 2.0) {
    TransientConfirmationBanner.show(on: self, message: message, duration: duration)
  }
}
