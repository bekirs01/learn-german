import Foundation

/// Single entry for Watch sensory cues. Haptics lead; sound is optional.
final class WatchFeedback {
    static let shared = WatchFeedback()

    let haptics = WatchHaptics()
    let sounds = WatchSoundEffects()

    var hapticsEnabled: Bool {
        get { haptics.isEnabled }
        set { haptics.isEnabled = newValue }
    }

    var soundsEnabled: Bool {
        get { sounds.isEnabled }
        set { sounds.isEnabled = newValue }
    }

    func play(_ event: WatchFeedbackEvent) {
        haptics.play(event)
        switch event {
        case .tap, .selection:
            // Keep everyday browsing quiet; haptics carry the tap.
            return
        case .success, .error:
            sounds.play(event)
        }
    }

    func playSound(_ event: WatchFeedbackEvent) {
        sounds.play(event)
    }
}
