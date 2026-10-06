import Foundation

/// Shared WatchConnectivity payload contract.
///
/// Flutter talks to iOS through MethodChannel `lingo_core/watch_sync`.
/// iOS and watchOS exchange plist-safe dictionaries so snapshots can be
/// queued, applied while the companion is unreachable, and cached locally.
enum WatchSyncChannelName {
    static let methodChannel = "lingo_core/watch_sync"
    static let isWatchSupported = "isWatchSupported"
    static let getWatchStatus = "getWatchStatus"
    static let sendTestPayload = "sendTestPayload"
    static let syncLearningPlan = "syncLearningPlan"
    static let clearLearningPlan = "clearLearningPlan"
}

enum WatchSyncEnvelopeKey {
    static let schema = "schema"
    static let kind = "kind"
    static let items = "items"
    static let currentId = "currentId"
    static let targetLanguage = "targetLanguage"
    static let learnerLanguage = "learnerLanguage"
    static let targetLanguageCode = "targetLanguageCode"
    static let learnerLanguageCode = "learnerLanguageCode"
    static let updatedAt = "updatedAt"
    static let kindSnapshot = "lingo.watch.snapshot"
    static let schemaVersion = 1
}

enum WatchContentType {
    static let word = "word"
    static let phrase = "phrase"
}

/// One learnable row. Extra fields are optional so later waves can add
/// schedule, pronunciation, and progress without breaking this envelope.
struct WatchLearningItem: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var type: String
    var targetText: String
    var translation: String
    var targetLanguage: String?
    var learnerLanguage: String?
    var pronunciationId: String?
    var schedule: WatchSchedulePayload?
    var isLearned: Bool?
    var isFavorite: Bool?

    var isPhrase: Bool {
        type.caseInsensitiveCompare(WatchContentType.phrase) == .orderedSame
    }

    static func parse(dictionary raw: [String: Any]) throws -> WatchLearningItem {
        let id = (raw["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let targetText = (raw["targetText"] as? String)?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        let translation = (raw["translation"] as? String)?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        let type = (raw["type"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !id.isEmpty else {
            throw WatchSyncError.invalidPayload("id is required")
        }
        guard !targetText.isEmpty else {
            throw WatchSyncError.invalidPayload("targetText is required")
        }
        guard !type.isEmpty else {
            throw WatchSyncError.invalidPayload("type is required")
        }

        return WatchLearningItem(
            id: id,
            type: type,
            targetText: targetText,
            translation: translation,
            targetLanguage: raw["targetLanguage"] as? String,
            learnerLanguage: raw["learnerLanguage"] as? String,
            pronunciationId: raw["pronunciationId"] as? String,
            schedule: WatchSchedulePayload.parse(raw["schedule"]),
            isLearned: raw["isLearned"] as? Bool,
            isFavorite: raw["isFavorite"] as? Bool
        )
    }

    func dictionary() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "type": type,
            "targetText": targetText,
            "translation": translation,
        ]
        if let targetLanguage, !targetLanguage.isEmpty {
            payload["targetLanguage"] = targetLanguage
        }
        if let learnerLanguage, !learnerLanguage.isEmpty {
            payload["learnerLanguage"] = learnerLanguage
        }
        if let pronunciationId, !pronunciationId.isEmpty {
            payload["pronunciationId"] = pronunciationId
        }
        if let schedule {
            payload["schedule"] = schedule.dictionary()
        }
        if let isLearned {
            payload["isLearned"] = isLearned
        }
        if let isFavorite {
            payload["isFavorite"] = isFavorite
        }
        return payload
    }
}

struct WatchSchedulePayload: Codable, Equatable, Hashable {
    var cadence: String?
    var hour: Int?
    var minute: Int?
    var timeZone: String?

    static func parse(_ raw: Any?) -> WatchSchedulePayload? {
        guard let raw = raw as? [String: Any], !raw.isEmpty else {
            return nil
        }
        return WatchSchedulePayload(
            cadence: raw["cadence"] as? String,
            hour: raw["hour"] as? Int,
            minute: raw["minute"] as? Int,
            timeZone: raw["timeZone"] as? String
        )
    }

    func dictionary() -> [String: Any] {
        var payload: [String: Any] = [:]
        if let cadence, !cadence.isEmpty {
            payload["cadence"] = cadence
        }
        if let hour {
            payload["hour"] = hour
        }
        if let minute {
            payload["minute"] = minute
        }
        if let timeZone, !timeZone.isEmpty {
            payload["timeZone"] = timeZone
        }
        return payload
    }
}

struct WatchSnapshot: Codable, Equatable {
    var items: [WatchLearningItem]
    var currentId: String?
    var targetLanguage: String?
    var learnerLanguage: String?
    var updatedAt: String?

    static let empty = WatchSnapshot(
        items: [],
        currentId: nil,
        targetLanguage: nil,
        learnerLanguage: nil,
        updatedAt: nil
    )

    var currentItem: WatchLearningItem? {
        if let currentId, let match = items.first(where: { $0.id == currentId }) {
            return match
        }
        return items.first
    }

    /// Cached rows from a previous target language must not appear in this
    /// German Watch app. Missing language metadata is kept until the next sync.
    var isStaleSourceLanguageCache: Bool {
        let values = [targetLanguage].compactMap { $0 } + items.compactMap(\.targetLanguage)
        for raw in values {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty {
                continue
            }
            let language = trimmed.split(separator: "-").first.map(String.init) ?? trimmed
            if language != "de" && language != "und" {
                return true
            }
        }
        return false
    }

    static func parse(dictionary raw: [String: Any]) throws -> WatchSnapshot {
        if let wrappedItems = raw[WatchSyncEnvelopeKey.items] as? [[String: Any]] {
            let items = try wrappedItems.map { try WatchLearningItem.parse(dictionary: $0) }
            return WatchSnapshot(
                items: items,
                currentId: raw[WatchSyncEnvelopeKey.currentId] as? String,
                targetLanguage: firstLanguage(
                    raw,
                    WatchSyncEnvelopeKey.targetLanguage,
                    WatchSyncEnvelopeKey.targetLanguageCode
                ),
                learnerLanguage: firstLanguage(
                    raw,
                    WatchSyncEnvelopeKey.learnerLanguage,
                    WatchSyncEnvelopeKey.learnerLanguageCode
                ),
                updatedAt: raw[WatchSyncEnvelopeKey.updatedAt] as? String
            )
        }
        let item = try WatchLearningItem.parse(dictionary: raw)
        return WatchSnapshot(
            items: [item],
            currentId: item.id,
            targetLanguage: item.targetLanguage ?? firstLanguage(
                raw,
                WatchSyncEnvelopeKey.targetLanguage,
                WatchSyncEnvelopeKey.targetLanguageCode
            ),
            learnerLanguage: item.learnerLanguage ?? firstLanguage(
                raw,
                WatchSyncEnvelopeKey.learnerLanguage,
                WatchSyncEnvelopeKey.learnerLanguageCode
            ),
            updatedAt: raw[WatchSyncEnvelopeKey.updatedAt] as? String
        )
    }

    func dictionary() -> [String: Any] {
        var payload: [String: Any] = [
            WatchSyncEnvelopeKey.schema: WatchSyncEnvelopeKey.schemaVersion,
            WatchSyncEnvelopeKey.kind: WatchSyncEnvelopeKey.kindSnapshot,
            WatchSyncEnvelopeKey.items: items.map { $0.dictionary() },
        ]
        if let currentId {
            payload[WatchSyncEnvelopeKey.currentId] = currentId
        }
        if let targetLanguage {
            payload[WatchSyncEnvelopeKey.targetLanguage] = targetLanguage
        }
        if let learnerLanguage {
            payload[WatchSyncEnvelopeKey.learnerLanguage] = learnerLanguage
        }
        if let updatedAt {
            payload[WatchSyncEnvelopeKey.updatedAt] = updatedAt
        }
        return payload
    }

    func upserting(_ item: WatchLearningItem) -> WatchSnapshot {
        var nextItems = items.filter { $0.id != item.id }
        nextItems.append(item)
        return WatchSnapshot(
            items: nextItems,
            currentId: item.id,
            targetLanguage: item.targetLanguage ?? targetLanguage,
            learnerLanguage: item.learnerLanguage ?? learnerLanguage,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    /// Production plans send `*Code` keys; the test envelope uses short names.
    private static func firstLanguage(_ raw: [String: Any], _ keys: String...) -> String? {
        for key in keys {
            guard let value = raw[key] as? String else {
                continue
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}

enum WatchSyncError: LocalizedError {
    case unsupported
    case sessionUnavailable
    case invalidPayload(String)

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Apple Watch is not supported on this device."
        case .sessionUnavailable:
            return "WatchConnectivity session is not available."
        case .invalidPayload(let reason):
            return "Watch test payload was invalid: \(reason)"
        }
    }
}
