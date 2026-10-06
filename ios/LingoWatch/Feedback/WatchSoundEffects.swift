import AVFoundation
import Foundation

/// Short bundled UI cues. Optional, quiet, and local-only.
final class WatchSoundEffects {
    var isEnabled = true
    var volume: Float = 0.28

    private var player: AVAudioPlayer?
    private var sessionReady = false

    func play(_ event: WatchFeedbackEvent) {
        guard isEnabled else {
            return
        }
        guard let name = resourceName(for: event) else {
            return
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            return
        }
        prepareSession()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            return
        }
    }

    private func resourceName(for event: WatchFeedbackEvent) -> String? {
        switch event {
        case .tap, .selection:
            return "sfx_tap"
        case .success:
            return "sfx_success"
        case .error:
            return "sfx_error"
        }
    }

    private func prepareSession() {
        guard !sessionReady else {
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            sessionReady = true
        } catch {
            sessionReady = false
        }
    }
}
