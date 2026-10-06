import Flutter
import Foundation
import WatchConnectivity

/// Flutter MethodChannel bridge for the Apple Watch companion.
///
/// Channel and method names are a frozen contract with the Dart layer:
/// `lingo_core/watch_sync` · `isWatchSupported` · `getWatchStatus` ·
/// `sendTestPayload` · `syncLearningPlan` · `clearLearningPlan`.
final class WatchSyncChannel {
    private let session: PhoneWatchSessionManager
    private var channel: FlutterMethodChannel?

    init(session: PhoneWatchSessionManager = .shared) {
        self.session = session
    }

    func attach(to messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: WatchSyncChannelName.methodChannel,
            binaryMessenger: messenger
        )
        self.channel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case WatchSyncChannelName.isWatchSupported:
            result(WCSession.isSupported())
        case WatchSyncChannelName.getWatchStatus:
            result(session.status)
        case WatchSyncChannelName.sendTestPayload:
            let arguments: [String: Any]
            if let dict = call.arguments as? [String: Any] {
                arguments = dict
            } else {
                arguments = [:]
            }
            do {
                result(try session.sendTestPayload(arguments))
            } catch {
                result(
                    FlutterError(
                        code: "watch_sync_failed",
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        case WatchSyncChannelName.syncLearningPlan:
            result(session.syncLearningPlan(call.arguments))
        case WatchSyncChannelName.clearLearningPlan:
            result(session.clearLearningPlan(call.arguments))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
