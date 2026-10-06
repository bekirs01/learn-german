import SwiftUI

@main
struct LingoWatchApp: App {
    @ObservedObject private var store = WatchItemStore.shared
    @ObservedObject private var session = WatchSessionManager.shared

    init() {
        WatchSessionManager.shared.activateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(store)
                .environmentObject(session)
                .environment(\.watchLearnerLanguage, store.learnerLanguageCode)
                .environment(\.locale, Locale(identifier: store.learnerLanguageCode))
                .environment(
                    \.layoutDirection,
                    WatchCopy.normalized(store.learnerLanguageCode) == "ar"
                        || WatchCopy.normalized(store.learnerLanguageCode) == "fa"
                        ? .rightToLeft
                        : .leftToRight
                )
        }
    }
}
