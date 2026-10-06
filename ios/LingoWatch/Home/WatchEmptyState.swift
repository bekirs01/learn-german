import SwiftUI

struct WatchEmptyState: View {
    var metrics: WatchMetrics
    @Environment(\.watchLearnerLanguage) private var language

    var body: some View {
        WatchPaperCard(metrics: metrics) {
            VStack(alignment: .leading, spacing: 8) {
                Circle()
                    .fill(WatchPalette.primary.opacity(0.14))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .strokeBorder(WatchPalette.primary.opacity(0.28), lineWidth: 0.8)
                    )
                    .overlay(
                        Circle()
                            .fill(WatchPalette.primary)
                            .frame(width: 7, height: 7)
                    )
                Text(WatchCopy.string(.setUpOnIPhone, language: language))
                    .font(WatchTypography.empty(metrics))
                    .foregroundStyle(WatchPalette.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .combine)
    }
}
