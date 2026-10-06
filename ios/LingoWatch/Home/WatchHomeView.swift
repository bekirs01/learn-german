import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject private var store: WatchItemStore
    @EnvironmentObject private var session: WatchSessionManager
    @Environment(\.watchLearnerLanguage) private var language

    var body: some View {
        GeometryReader { proxy in
            let metrics = WatchMetrics(size: proxy.size)
            ZStack {
                WatchPaperBackground()
                VStack(spacing: metrics.stackGap) {
                    header(metrics)
                    if let item = store.currentItem {
                        WatchLearningCard(
                            item: item,
                            index: store.selectedIndex,
                            total: store.items.count,
                            metrics: metrics
                        )
                        if store.items.count > 1 {
                            browseRow(metrics)
                        }
                    } else {
                        WatchEmptyState(metrics: metrics)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, metrics.gutter)
                .padding(.bottom, 2)
            }
        }
    }

    private func header(_ metrics: WatchMetrics) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2.4, style: .continuous)
                .fill(WatchPalette.primary)
                .frame(width: metrics.markSize, height: metrics.markSize)
            Text(WatchCopy.string(.appMark, language: language))
                .font(WatchTypography.mark(metrics))
                .foregroundStyle(WatchPalette.ink)
            Spacer(minLength: 4)
            if store.hasItems && !session.isReachable {
                Text(WatchCopy.string(.onWatch, language: language))
                    .font(WatchTypography.caption(metrics))
                    .foregroundStyle(WatchPalette.inkFaint)
            }
        }
        .padding(.top, 1)
    }

    private func browseRow(_ metrics: WatchMetrics) -> some View {
        HStack(spacing: metrics.isCompact ? 8 : 10) {
            WatchCircularButton(systemName: "chevron.left", size: metrics.buttonSize) {
                store.selectPrevious()
            }
            .accessibilityLabel(Text(WatchCopy.string(.previous, language: language)))
            Spacer(minLength: 0)
            WatchCircularButton(systemName: "chevron.right", size: metrics.buttonSize) {
                store.selectNext()
            }
            .accessibilityLabel(Text(WatchCopy.string(.next, language: language)))
        }
        .padding(.horizontal, metrics.isCompact ? 4 : 6)
    }
}

#Preview("Empty") {
    WatchHomeView()
        .environmentObject(WatchItemStore(snapshot: .empty))
        .environmentObject(WatchSessionManager())
}

#Preview("Word") {
    WatchHomeView()
        .environmentObject(
            WatchItemStore(
                snapshot: WatchSnapshot(
                    items: [
                        WatchLearningItem(
                            id: "word.basics.hello",
                            type: WatchContentType.word,
                            targetText: "Hallo",
                            translation: "Merhaba"
                        ),
                    ],
                    currentId: "word.basics.hello"
                )
            )
        )
        .environmentObject(WatchSessionManager())
}
