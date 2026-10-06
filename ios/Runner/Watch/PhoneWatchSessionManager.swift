import Foundation
import WatchConnectivity

/// iPhone-side WatchConnectivity session.
///
/// Safe on devices with no paired Watch: `WCSession.isSupported()` is checked
/// before any session access. Missing hardware never crashes the Flutter host.
final class PhoneWatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSessionManager()

    private var session: WCSession?
    private let lock = NSLock()
    private var pendingPlan: [String: Any]?

    private override init() {
        super.init()
    }

    var status: [String: Bool] {
        lock.lock()
        defer { lock.unlock() }
        guard WCSession.isSupported(), let session else {
            return [
                "supported": false,
                "paired": false,
                "watchAppInstalled": false,
                "reachable": false,
            ]
        }
        return [
            "supported": true,
            "paired": session.isPaired,
            "watchAppInstalled": session.isWatchAppInstalled,
            "reachable": session.isReachable,
        ]
    }

    func activateIfNeeded() {
        guard WCSession.isSupported() else {
            return
        }
        lock.lock()
        if session == nil {
            let session = WCSession.default
            session.delegate = self
            self.session = session
        }
        let session = self.session
        lock.unlock()
        restorePendingPlanIfNeeded()
        guard let session else {
            return
        }
        if session.activationState == .notActivated {
            session.activate()
        } else if session.activationState == .activated {
            _ = flushPendingPlan(on: session)
        }
    }

    /// Re-applies the latest learning plan after the iPhone becomes active.
    func retryPendingPlan() {
        activateIfNeeded()
        lock.lock()
        let session = self.session
        lock.unlock()
        guard let session else {
            return
        }
        _ = flushPendingPlan(on: session)
    }

    func sendTestPayload(_ raw: [String: Any]) throws -> [String: Any] {
        activateIfNeeded()
        guard WCSession.isSupported() else {
            throw WatchSyncError.unsupported
        }
        lock.lock()
        let session = self.session
        lock.unlock()
        guard let session else {
            throw WatchSyncError.sessionUnavailable
        }

        let item = try WatchLearningItem.parse(dictionary: raw)
        let snapshot = WatchSnapshot(
            items: [item],
            currentId: item.id,
            targetLanguage: item.targetLanguage,
            learnerLanguage: item.learnerLanguage,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        let envelope = snapshot.dictionary()

        do {
            try session.updateApplicationContext(envelope)
        } catch {
            // Reachability or activation can still succeed via user-info queue.
        }
        _ = session.transferUserInfo(envelope)

        let reachable = session.isReachable
        if reachable {
            session.sendMessage(
                envelope,
                replyHandler: { _ in },
                errorHandler: { _ in }
            )
        }

        return [
            "ok": true,
            "queued": true,
            "reachable": reachable,
            "id": item.id,
        ]
    }

    /// Replaces the latest Watch learning plan via application context.
    /// Queues even when the Watch is not currently reachable.
    func syncLearningPlan(_ raw: Any?) -> [String: Any] {
        activateIfNeeded()
        guard WCSession.isSupported() else {
            return WatchLearningPlanCodec.outcome(ok: false, name: "unavailable")
        }
        lock.lock()
        let session = self.session
        lock.unlock()
        guard let session else {
            return WatchLearningPlanCodec.outcome(ok: false, name: "unavailable")
        }
        if !session.isPaired {
            return WatchLearningPlanCodec.outcome(ok: false, name: "unavailable")
        }
        if !session.isWatchAppInstalled {
            return WatchLearningPlanCodec.outcome(ok: false, name: "appNotInstalled")
        }
        do {
            let payload = try WatchLearningPlanCodec.plist(raw)
            storePendingPlan(payload)
            _ = flushPendingPlan(on: session)
            let reachable = session.isReachable
            return WatchLearningPlanCodec.outcome(
                ok: true,
                name: reachable ? "sent" : "saved",
                reachable: reachable
            )
        } catch {
            return WatchLearningPlanCodec.outcome(ok: false, name: "unavailable")
        }
    }

    @discardableResult
    private func flushPendingPlan(on session: WCSession) -> Bool {
        lock.lock()
        let payload = pendingPlan
        lock.unlock()
        guard let payload else {
            return false
        }
        if session.activationState != .activated {
            return false
        }
        if NSDictionary(dictionary: session.applicationContext).isEqual(to: payload) {
            return true
        }
        do {
            try session.updateApplicationContext(payload)
            return true
        } catch {
            // Keep the pending plan. Application context is retried when the
            // session activates or Watch state changes. Never require sendMessage.
            return false
        }
    }

    private func storePendingPlan(_ payload: [String: Any]) {
        lock.lock()
        pendingPlan = payload
        lock.unlock()
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload)
        else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.pendingPlanDefaultsKey)
    }

    private func restorePendingPlanIfNeeded() {
        lock.lock()
        let hasPending = pendingPlan != nil
        lock.unlock()
        if hasPending {
            return
        }
        guard let data = UserDefaults.standard.data(forKey: Self.pendingPlanDefaultsKey),
              let object = try? JSONSerialization.jsonObject(with: data),
              let payload = object as? [String: Any]
        else {
            return
        }
        lock.lock()
        pendingPlan = payload
        lock.unlock()
    }

    private static let pendingPlanDefaultsKey = "lingo.watch.pendingLearningPlan"

    func clearLearningPlan(_ raw: Any?) -> [String: Any] {
        let payload: Any
        if raw == nil {
            payload = WatchLearningPlanCodec.empty()
        } else {
            payload = raw as Any
        }
        return syncLearningPlan(payload)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // Status is read live from WCSession; no extra state is required.
        if error != nil {
            return
        }
        _ = activationState
        _ = flushPendingPlan(on: session)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        _ = flushPendingPlan(on: session)
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        _ = flushPendingPlan(on: session)
    }
}

/// Plist-safe encoder for the frozen WAVE 2 learning-plan contract.
enum WatchLearningPlanCodec {
    static func outcome(ok: Bool, name: String, reachable: Bool = false) -> [String: Any] {
        [
            "ok": ok,
            "outcome": name,
            "queued": ok,
            "reachable": reachable,
        ]
    }

    static func empty() -> [String: Any] {
        [
            "schemaVersion": 1,
            "targetLanguageCode": "",
            "learnerLanguageCode": "",
            "items": [[String: Any]](),
            "schedule": [
                "enabled": false,
                "mode": "window_frequency",
                "startMinutes": 9 * 60,
                "endMinutes": 21 * 60,
                "timesPerDay": 5,
            ] as [String: Any],
            "updatedAtEpochMs": Int(Date().timeIntervalSince1970 * 1000),
        ]
    }

    static func plist(_ raw: Any?) throws -> [String: Any] {
        guard let dict = raw as? [String: Any] else {
            throw WatchSyncError.invalidPayload("learning plan is required")
        }
        let schemaVersion = intValue(dict["schemaVersion"]) ?? 1
        let target = stringValue(dict["targetLanguageCode"])
        let learner = stringValue(dict["learnerLanguageCode"])

        var items: [[String: Any]] = []
        if let rawItems = dict["items"] as? [Any] {
            for entry in rawItems {
                guard let item = entry as? [String: Any] else {
                    continue
                }
                let id = stringValue(item["id"])
                let type = stringValue(item["type"])
                let targetText = stringValue(item["targetText"])
                let translation = stringValue(item["translation"])
                let pronunciationId = stringValue(item["pronunciationId"])
                guard !id.isEmpty, !type.isEmpty, !targetText.isEmpty else {
                    throw WatchSyncError.invalidPayload("item fields are required")
                }
                var row: [String: Any] = [
                    "id": id,
                    "type": type,
                    "targetText": targetText,
                    "translation": translation,
                ]
                if !pronunciationId.isEmpty {
                    row["pronunciationId"] = pronunciationId
                }
                items.append(row)
            }
        }

        if !items.isEmpty {
            guard !target.isEmpty else {
                throw WatchSyncError.invalidPayload("targetLanguageCode is required")
            }
            guard !learner.isEmpty else {
                throw WatchSyncError.invalidPayload("learnerLanguageCode is required")
            }
        }

        let schedule = schedulePlist(dict["schedule"])
        let updatedAt = intValue(dict["updatedAtEpochMs"]) ?? Int(Date().timeIntervalSince1970 * 1000)

        return [
            "schemaVersion": schemaVersion,
            "targetLanguageCode": target,
            "learnerLanguageCode": learner,
            "items": items,
            "schedule": schedule,
            "updatedAtEpochMs": updatedAt,
        ]
    }

    private static func schedulePlist(_ raw: Any?) -> [String: Any] {
        let dict = raw as? [String: Any]
        let enabled = dict?["enabled"] as? Bool ?? false
        let mode = stringValue(dict?["mode"]).isEmpty ? "window_frequency" : stringValue(dict?["mode"])
        let start = intValue(dict?["startMinutes"]) ?? (9 * 60)
        let end = intValue(dict?["endMinutes"]) ?? (21 * 60)
        let times = intValue(dict?["timesPerDay"]) ?? 5
        return [
            "enabled": enabled,
            "mode": mode,
            "startMinutes": start,
            "endMinutes": end,
            "timesPerDay": times,
        ]
    }

    private static func stringValue(_ raw: Any?) -> String {
        if let value = raw as? String {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private static func intValue(_ raw: Any?) -> Int? {
        if let value = raw as? Int {
            return value
        }
        if let value = raw as? NSNumber {
            return value.intValue
        }
        if let value = raw as? String {
            return Int(value)
        }
        return nil
    }
}
