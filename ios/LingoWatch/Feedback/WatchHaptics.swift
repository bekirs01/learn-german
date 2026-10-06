import WatchKit

enum WatchFeedbackEvent {
    case tap
    case selection
    case success
    case error
}

/// Central Watch haptics. Views must not call `WKInterfaceDevice` directly.
final class WatchHaptics {
    var isEnabled = true

    func play(_ event: WatchFeedbackEvent) {
        guard isEnabled else {
            return
        }
        WKInterfaceDevice.current().play(haptic(for: event))
    }

    private func haptic(for event: WatchFeedbackEvent) -> WKHapticType {
        switch event {
        case .tap:
            return .click
        case .selection:
            return .click
        case .success:
            return .success
        case .error:
            return .failure
        }
    }
}
