import SwiftUI

/// Soft crumpled stationery, derived from the iPhone paper photograph.
struct WatchPaperBackground: View {
    var body: some View {
        ZStack {
            WatchPalette.canvas
            Image("PaperCrumpled")
                .resizable()
                .scaledToFill()
                .opacity(0.90)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            WatchPalette.wash
        }
        .ignoresSafeArea()
    }
}

struct WatchPaperCard<Content: View>: View {
    var emphasized: Bool = false
    var selected: Bool = false
    var metrics: WatchMetrics? = nil
    @ViewBuilder var content: Content

    var body: some View {
        let radius = metrics?.cardRadius ?? 16
        let padding = metrics?.cardPadding ?? 10
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(WatchPalette.paperFill)
                    .shadow(
                        color: WatchPalette.shadow.opacity(selected || emphasized ? 0.14 : 0.08),
                        radius: selected ? 5 : 4,
                        x: 0,
                        y: selected ? 2 : 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.7)
            )
    }

    private var borderColor: Color {
        if selected {
            return WatchPalette.primary.opacity(0.48)
        }
        if emphasized {
            return WatchPalette.accent.opacity(0.28)
        }
        return WatchPalette.paperRim
    }
}
