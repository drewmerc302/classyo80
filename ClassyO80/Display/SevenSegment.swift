import SwiftUI

/// The seven bars of an LCD digit.
struct Segments: OptionSet, Sendable {
    let rawValue: UInt8

    static let top = Segments(rawValue: 1 << 0)
    static let upperRight = Segments(rawValue: 1 << 1)
    static let lowerRight = Segments(rawValue: 1 << 2)
    static let bottom = Segments(rawValue: 1 << 3)
    static let lowerLeft = Segments(rawValue: 1 << 4)
    static let upperLeft = Segments(rawValue: 1 << 5)
    static let middle = Segments(rawValue: 1 << 6)

    /// Casio glyphs: 6 has its top bar, 9 its bottom bar, and 7 its upper-left hook.
    init?(digit: Character) {
        switch digit {
        case "0": self = [.top, .upperRight, .lowerRight, .bottom, .lowerLeft, .upperLeft]
        case "1": self = [.upperRight, .lowerRight]
        case "2": self = [.top, .upperRight, .middle, .lowerLeft, .bottom]
        case "3": self = [.top, .upperRight, .middle, .lowerRight, .bottom]
        case "4": self = [.upperLeft, .middle, .upperRight, .lowerRight]
        case "5": self = [.top, .upperLeft, .middle, .lowerRight, .bottom]
        case "6": self = [.top, .upperLeft, .middle, .lowerLeft, .lowerRight, .bottom]
        case "7": self = [.upperLeft, .top, .upperRight, .lowerRight]
        case "8": self = [.top, .upperRight, .lowerRight, .bottom, .lowerLeft, .upperLeft, .middle]
        case "9": self = [.top, .upperRight, .lowerRight, .bottom, .upperLeft, .middle]
        default: return nil
        }
    }

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

/// One LCD digit position: the slanted seven-segment glyph plus its decimal point and its
/// three-digit separator tick, drawn as a single path. The rect is one cell pitch wide.
struct SevenSegmentCell: Shape {
    var segments: Segments
    var hasPoint: Bool
    var hasSeparator: Bool

    /// Share of the cell pitch taken by the slanted glyph; the rest holds the point and tick.
    static let glyphShare: CGFloat = 0.81
    static let slant: CGFloat = tan(6 * .pi / 180)

    init(cell: LCDCell) {
        segments = cell.digit.flatMap(Segments.init(digit:)) ?? []
        hasPoint = cell.hasPoint
        hasSeparator = cell.hasSeparator
    }

    func path(in rect: CGRect) -> Path {
        let height = rect.height
        let lean = height * Self.slant
        let width = rect.width * Self.glyphShare - lean
        let thickness = height * 0.101
        let gap = height * 0.016
        let half = thickness / 2

        // Unslanted glyph coordinates, leaned right with height like the real LCD.
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x + (height - y) / height * lean, y: rect.minY + y)
        }

        func horizontal(_ y: CGFloat) -> [CGPoint] {
            let x0 = half + gap, x1 = width - half - gap
            return [
                point(x0, y), point(x0 + half, y - half), point(x1 - half, y - half),
                point(x1, y), point(x1 - half, y + half), point(x0 + half, y + half),
            ]
        }

        func vertical(_ x: CGFloat, from y0: CGFloat, to y1: CGFloat) -> [CGPoint] {
            let top = y0 + gap, bottom = y1 - gap
            return [
                point(x, top), point(x + half, top + half), point(x + half, bottom - half),
                point(x, bottom), point(x - half, bottom - half), point(x - half, top + half),
            ]
        }

        let left = half, right = width - half
        let upper = half, middle = height / 2, lower = height - half

        var path = Path()
        let bars: [(Segments, [CGPoint])] = [
            (.top, horizontal(upper)),
            (.middle, horizontal(middle)),
            (.bottom, horizontal(lower)),
            (.upperLeft, vertical(left, from: upper, to: middle)),
            (.upperRight, vertical(right, from: upper, to: middle)),
            (.lowerLeft, vertical(left, from: middle, to: lower)),
            (.lowerRight, vertical(right, from: middle, to: lower)),
        ]
        for (segment, outline) in bars where segments.contains(segment) {
            path.addLines(outline)
            path.closeSubpath()
        }

        let gutter = rect.width * (1 - Self.glyphShare)
        if hasPoint {
            let radius = height * 0.043
            let center = point(width + gutter * 0.5, height - radius * 0.9)
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        if hasSeparator {
            let x = width + gutter * 0.55
            let length = height * 0.2
            let topHalf = thickness * 0.42, bottomHalf = thickness * 0.16
            path.addLines([
                point(x - topHalf, 0), point(x + topHalf, 0),
                point(x + bottomHalf, length), point(x - bottomHalf, length),
            ])
            path.closeSubpath()
        }
        return path
    }
}
