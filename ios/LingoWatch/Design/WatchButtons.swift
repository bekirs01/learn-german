import SwiftUI

/// Fast, shallow press: scale and a quiet highlight, then a short settle.
struct WatchPressStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeOut(duration: 0.11), value: configuration.isPressed)
    }
}

struct WatchCircularButton: View {
    let systemName: String
    var selected: Bool = false
    var enabled: Bool = true
    var size: CGFloat = 36
    let action: () -> Void

    var body: some View {
        Button {
            WatchFeedback.shared.play(.tap)
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: max(12, size * 0.36), weight: .semibold))
                .foregroundStyle(selected ? WatchPalette.onPrimary : WatchPalette.primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(selected ? WatchPalette.primary : WatchPalette.raised)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            selected ? WatchPalette.primary.opacity(0.2) : WatchPalette.paperRim,
                            lineWidth: 0.7
                        )
                )
                .shadow(color: WatchPalette.shadow.opacity(0.10), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(WatchPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.38)
    }
}

struct WatchCompactButton: View {
    let title: LocalizedStringResource
    var selected: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            WatchFeedback.shared.play(selected ? .selection : .tap)
            action()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? WatchPalette.onPrimary : WatchPalette.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? WatchPalette.primary : WatchPalette.raised)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            selected ? WatchPalette.primary.opacity(0.2) : WatchPalette.paperRim,
                            lineWidth: 0.7
                        )
                )
        }
        .buttonStyle(WatchPressStyle(scale: 0.97))
    }
}
