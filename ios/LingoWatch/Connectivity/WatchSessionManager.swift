import Combine
import Foundation
import WatchConnectivity

/// Watch-side WatchConnectivity session. Applies snapshots into the local cache
/// so content remains available when the iPhone is temporarily unreachable.
final class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManager()

    @Published private(set) var isReachable = false
    @Published private(set) var isActivated = false

    private let store: WatchItemStore
    private var session: WCSession?

    init(store: WatchItemStore = .shared) {
        self.store = store
        super.init()
    }

    func activateIfNeeded() {
        guard WCSession.isSupported() else {
            return
        }
        if session == nil {
            let session = WCSession.default
            session.delegate = self
            self.session = session
        }
        guard let session else {
            return
        }
        if session.activationState == .notActivated {
            session.activate()
        } else {
            apply(session: session)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isActivated = activationState == .activated
            self.isReachable = session.isReachable
            if activationState == .activated {
                self.apply(session: session)
            }
        }
        _ = error
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        ingest(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        ingest(userInfo)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        ingest(message)
        replyHandler(["ok": true])
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        ingest(message)
    }

    private func apply(session: WCSession) {
        isReachable = session.isReachable
        if !session.receivedApplicationContext.isEmpty {
            ingest(session.receivedApplicationContext)
        }
    }

    private func ingest(_ raw: [String: Any]) {
        do {
            let snapshot = try WatchSnapshot.parse(dictionary: raw)
            DispatchQueue.main.async {
                self.store.apply(snapshot)
            }
        } catch {
            return
        }
    }
}
