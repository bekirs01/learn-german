import Combine
import Foundation

/// Local JSON cache so previously synced items stay on Watch when iPhone
/// is unreachable. Not a database; one snapshot file is enough for this wave.
final class WatchItemStore: ObservableObject {
    static let shared = WatchItemStore()

    @Published private(set) var snapshot: WatchSnapshot

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(snapshot: WatchSnapshot? = nil) {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        decoder = JSONDecoder()
        var replacedStaleCache = false
        if let snapshot {
            self.snapshot = snapshot
        } else {
            let loaded = WatchItemStore.loadFromDisk(decoder: decoder) ?? .empty
            if loaded.isStaleSourceLanguageCache {
                self.snapshot = .empty
                replacedStaleCache = true
            } else {
                self.snapshot = loaded
            }
        }
        if trimmed(self.snapshot.learnerLanguage) == nil,
           let stored = UserDefaults.standard.string(forKey: Self.learnerLanguageDefaultsKey)
        {
            let next = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            if !next.isEmpty {
                self.snapshot.learnerLanguage = next
            }
        }
        if replacedStaleCache {
            persist()
        }
    }

    var items: [WatchLearningItem] { snapshot.items }
    var currentItem: WatchLearningItem? { snapshot.currentItem }
    var hasItems: Bool { !snapshot.items.isEmpty }
    var learnerLanguageCode: String {
        WatchCopy.normalized(
            trimmed(snapshot.learnerLanguage) ?? storedLearnerLanguage() ?? "en"
        )
    }

    var selectedIndex: Int {
        guard let current = snapshot.currentItem else {
            return 0
        }
        return snapshot.items.firstIndex(where: { $0.id == current.id }) ?? 0
    }

    func apply(_ snapshot: WatchSnapshot) {
        var next = snapshot
        if next.currentId == nil {
            next.currentId = next.items.first?.id
        }
        if let incoming = trimmed(next.learnerLanguage) {
            persistLearnerLanguage(incoming)
        } else if let stored = storedLearnerLanguage() {
            next.learnerLanguage = stored
        }
        self.snapshot = next
        persist()
    }

    func ingestTestItem(_ item: WatchLearningItem) {
        apply(snapshot.upserting(item))
    }

    func selectNext() {
        guard !items.isEmpty else {
            return
        }
        let index = (selectedIndex + 1) % items.count
        selectIndex(index)
        WatchFeedback.shared.play(.selection)
    }

    func selectPrevious() {
        guard !items.isEmpty else {
            return
        }
        let index = (selectedIndex - 1 + items.count) % items.count
        selectIndex(index)
        WatchFeedback.shared.play(.selection)
    }

    private func selectIndex(_ index: Int) {
        guard items.indices.contains(index) else {
            return
        }
        var next = snapshot
        next.currentId = items[index].id
        snapshot = next
        persist()
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let next = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return next.isEmpty ? nil : next
    }

    private func persistLearnerLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: Self.learnerLanguageDefaultsKey)
    }

    private func storedLearnerLanguage() -> String? {
        trimmed(UserDefaults.standard.string(forKey: Self.learnerLanguageDefaultsKey))
    }

    private func persist() {
        do {
            let data = try encoder.encode(snapshot)
            try FileManager.default.createDirectory(
                at: WatchItemStore.directoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: WatchItemStore.fileURL, options: [.atomic])
        } catch {
            return
        }
    }

    private static func loadFromDisk(decoder: JSONDecoder) -> WatchSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return try? decoder.decode(WatchSnapshot.self, from: data)
    }

    private static let learnerLanguageDefaultsKey = "lingo.watch.learnerLanguage"

    private static var directoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LingoWatch", isDirectory: true)
    }

    private static var fileURL: URL {
        directoryURL.appendingPathComponent("cache.json")
    }
}
