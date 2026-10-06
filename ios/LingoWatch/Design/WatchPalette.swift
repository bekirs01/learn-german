import SwiftUI

/// Harbor teal / cream identity mirrored from Lingo Core iPhone tokens.
enum WatchPalette {
    static let primary = Color(red: 27 / 255, green: 101 / 255, blue: 104 / 255)
    static let onPrimary = Color.white
    static let accent = Color(red: 196 / 255, green: 106 / 255, blue: 60 / 255)
    static let tertiary = Color(red: 106 / 255, green: 90 / 255, blue: 134 / 255)
    static let success = Color(red: 58 / 255, green: 127 / 255, blue: 98 / 255)
    static let danger = Color(red: 192 / 255, green: 69 / 255, blue: 69 / 255)
    static let canvas = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)
    static let surface = Color(red: 250 / 255, green: 246 / 255, blue: 239 / 255)
    static let raised = Color(red: 255 / 255, green: 251 / 255, blue: 246 / 255)
    static let ink = Color(red: 26 / 255, green: 31 / 255, blue: 33 / 255)
    static let inkMuted = Color(red: 26 / 255, green: 31 / 255, blue: 33 / 255).opacity(0.62)
    static let inkFaint = Color(red: 26 / 255, green: 31 / 255, blue: 33 / 255).opacity(0.42)
    static let paperFill = Color(red: 255 / 255, green: 252 / 255, blue: 247 / 255).opacity(0.78)
    static let paperRim = Color.white.opacity(0.62)
    static let hairline = Color(red: 26 / 255, green: 31 / 255, blue: 33 / 255).opacity(0.10)
    static let shadow = Color(red: 42 / 255, green: 34 / 255, blue: 28 / 255)
    static let wash = canvas.opacity(0.16)
}

struct WatchMetrics {
    let size: CGSize

    var isCompact: Bool { size.width < 180 }
    var gutter: CGFloat { isCompact ? 6 : 8 }
    var stackGap: CGFloat { isCompact ? 5 : 7 }
    var cardRadius: CGFloat { isCompact ? 14 : 16 }
    var cardPadding: CGFloat { isCompact ? 8 : 10 }
    var wordSize: CGFloat { isCompact ? 20 : 23 }
    var translationSize: CGFloat { isCompact ? 13 : 14.5 }
    var captionSize: CGFloat { isCompact ? 10 : 11 }
    var headerSize: CGFloat { isCompact ? 12 : 13 }
    var buttonSize: CGFloat { isCompact ? 34 : 38 }
    var iconSize: CGFloat { isCompact ? 12 : 13 }
    var markSize: CGFloat { isCompact ? 8 : 9 }
}

enum WatchTypography {
    static func mark(_ metrics: WatchMetrics) -> Font {
        .system(size: metrics.headerSize, weight: .semibold, design: .default)
    }

    static func word(_ metrics: WatchMetrics) -> Font {
        .system(size: metrics.wordSize, weight: .semibold, design: .default)
    }

    static func translation(_ metrics: WatchMetrics) -> Font {
        .system(size: metrics.translationSize, weight: .regular, design: .default)
    }

    static func caption(_ metrics: WatchMetrics) -> Font {
        .system(size: metrics.captionSize, weight: .semibold, design: .default)
    }

    static func empty(_ metrics: WatchMetrics) -> Font {
        .system(size: metrics.isCompact ? 14 : 15.5, weight: .semibold, design: .default)
    }
}
