import SwiftUI

struct WatchLearningCard: View {
    let item: WatchLearningItem
    var index: Int = 0
    var total: Int = 1
    var metrics: WatchMetrics
    @Environment(\.watchLearnerLanguage) private var language

    var body: some View {
        WatchPaperCard(emphasized: true, selected: true, metrics: metrics) {
            VStack(alignment: .leading, spacing: metrics.isCompact ? 5 : 6) {
                HStack(spacing: 6) {
                    Text(WatchCopy.string(.today, language: language))
                        .font(WatchTypography.caption(metrics))
                        .foregroundStyle(WatchPalette.inkFaint)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Spacer(minLength: 4)
                    typeChip
                    if total > 1 {
                        Text("\(index + 1)/\(total)")
                            .font(WatchTypography.caption(metrics))
                            .foregroundStyle(WatchPalette.inkFaint)
                            .monospacedDigit()
                    }
                }
                Text(item.targetText)
                    .font(WatchTypography.word(metrics))
                    .foregroundStyle(WatchPalette.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
                if !item.translation.isEmpty {
                    Text(item.translation)
                        .font(WatchTypography.translation(metrics))
                        .foregroundStyle(WatchPalette.inkMuted)
                        .lineLimit(4)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var typeChip: some View {
        Text(WatchCopy.contentType(isPhrase: item.isPhrase, language: language))
            .font(.system(size: metrics.captionSize, weight: .semibold))
            .foregroundStyle(item.isPhrase ? WatchPalette.tertiary : WatchPalette.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        (item.isPhrase ? WatchPalette.tertiary : WatchPalette.primary)
                            .opacity(0.12)
                    )
            )
    }
}
