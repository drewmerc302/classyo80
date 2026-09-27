import SwiftUI

/// Front-panel measurements of the real unit, in millimetres from the top-left corner.
///
/// Measured off a front-panel photograph of the unit — Casio's, so not kept in this repo — scaled
/// to the published 103 x 147 mm footprint (3.44 px per mm in that photo). Views map these through
/// `PanelScale`, which stretches the calculator to fill the screen.
enum Panel {
    static let size = CGSize(width: 103, height: 147)
    static let cornerRadius: CGFloat = 6.5
    /// Width of the dark edge around the two plates.
    static let rim: CGFloat = 2.2
    /// Seam between the smooth top plate and the brushed keypad plate.
    static let seamY: CGFloat = 53.7
    /// Where the brushed keypad plate meets the bevelled bottom lip.
    static let lipY: CGFloat = 137.8
    static let lipBottom: CGFloat = 144.6

    static let solarPanel = CGRect(x: 36.3, y: 10.8, width: 36.0, height: 10.2)
    /// Printed where the real unit says CASIO; shrinks to fit the `brand` slot left of the solar cell.
    static let brandName = "CLASSY-O"
    static let brand = CGRect(x: 8.9, y: 13.3, width: 25, height: 5.2)
    /// Printed where the real unit says MS-80BM. Ours, not Casio's, so the panel carries no mark
    /// of theirs; the engine still follows their manual.
    static let modelName = "CO-80BM"
    static let model = CGRect(x: 77.6, y: 14.2, width: 18, height: 4.0)
    static let lcd = CGRect(x: 11.2, y: 26.0, width: 80.6, height: 22.6)

    // Key grid. The digit block (columns 2 to 4) sits tighter than the outer columns.
    static let columnX: [CGFloat] = [8.5, 27.6, 44.5, 61.4, 80.5]
    static let rowY: [CGFloat] = [59.4, 69.0, 82.95, 96.9, 110.85, 124.8]
    static let keyWidth: CGFloat = 14.0
    static let keyHeight: CGFloat = 11.6
    static let smallKeyHeight: CGFloat = 7.2
    /// Invisible margin added around each key's touch area (under half the narrowest gap).
    static let touchSlop: CGFloat = 1.1

    static func keyRect(row: Int, column: Int, rowSpan: Int = 1) -> CGRect {
        let lastRow = row + rowSpan - 1
        let bottom = rowY[lastRow] + (lastRow == 0 ? smallKeyHeight : keyHeight)
        return CGRect(x: columnX[column], y: rowY[row], width: keyWidth, height: bottom - rowY[row])
    }
}

/// Maps panel millimetres to screen points, stretching the calculator to fill the screen.
///
/// Text, strokes and corner radii use `detail`, the uniform aspect-fit scale, so nothing looks
/// squashed. Geometry stretches instead: extra height goes a little to the top plate (capped at
/// `maxTopStretch`) and the rest to the keypad plate, so keys and gaps grow taller while the bottom
/// lip keeps its real thickness. Extra width (landscape iPad) widens everything up to
/// `maxWidthStretch`; anything beyond the caps is left as margin.
struct PanelScale: Equatable {
    static let maxWidthStretch: CGFloat = 1.35
    static let maxHeightStretch: CGFloat = 1.6
    static let maxTopStretch: CGFloat = 1.15

    /// Points per millimetre for text, strokes and corner radii.
    let detail: CGFloat
    /// Points per millimetre across the panel.
    let x: CGFloat
    /// Points per millimetre down the top plate (wordmark, solar cell, LCD).
    let top: CGFloat
    /// Points per millimetre down the keypad plate.
    let keypad: CGFloat

    init(fitting available: CGSize) {
        let uniform = min(available.width / Panel.size.width, available.height / Panel.size.height)
        detail = uniform
        x = min(available.width / Panel.size.width, uniform * Self.maxWidthStretch)
        let height = min(available.height, Panel.size.height * uniform * Self.maxHeightStretch)
        let extra = height - Panel.size.height * uniform
        let topExtra = min(extra, Panel.seamY * uniform * (Self.maxTopStretch - 1))
        top = uniform + topExtra / Panel.seamY
        keypad = uniform + (extra - topExtra) / (Panel.lipY - Panel.seamY)
    }

    /// Points from the top edge for a panel position in millimetres.
    func y(_ mm: CGFloat) -> CGFloat {
        if mm <= Panel.seamY { return mm * top }
        let seam = Panel.seamY * top
        if mm <= Panel.lipY { return seam + (mm - Panel.seamY) * keypad }
        return seam + (Panel.lipY - Panel.seamY) * keypad + (mm - Panel.lipY) * detail
    }

    var size: CGSize { CGSize(width: Panel.size.width * x, height: y(Panel.size.height)) }

    // MARK: Roomy keypad

    /// Keypad stretch (relative to `detail`) from which the roomy keypad kicks in. Phones sit
    /// around 1.3 to 1.6; iPads in portrait are close to 1.
    static let roomyThreshold: CGFloat = 1.25
    /// How far the small top row moves up, in millimetres, to widen the C1 to C3 gap.
    static let topRowLift: CGFloat = 2.0
    /// Share of a key cap's height given back as padding on the rows below the top row.
    static let capShrink: CGFloat = 0.10

    /// Tall layouts stretch keys into tall rectangles. The roomy keypad opens the gap under the
    /// top row (with bigger C1 to C3 legends) and shortens the other key caps instead.
    var usesRoomyKeypad: Bool { keypad >= detail * Self.roomyThreshold }

    /// A key's touch rectangle in millimetres, with the top row lifted in the roomy keypad.
    func keyRect(row: Int, column: Int, rowSpan: Int = 1) -> CGRect {
        var rect = Panel.keyRect(row: row, column: column, rowSpan: rowSpan)
        if usesRoomyKeypad, row == 0 { rect.origin.y -= Self.topRowLift }
        return rect
    }

    /// Millimetres trimmed from the top and the bottom of a key cap inside its touch rectangle,
    /// keeping the cap centred. Applied per row, so the double-height + stays aligned.
    func capInset(row: Int) -> CGFloat {
        usesRoomyKeypad && row > 0 ? Panel.keyHeight * Self.capShrink / 2 : 0
    }

    /// Centre of the gap between the top row and the memory keys, where C1 to C3 are printed.
    var currencyLegendY: CGFloat {
        (keyRect(row: 0, column: 0).maxY + keyRect(row: 1, column: 0).minY) / 2
    }

    /// Font size of the C1 to C3 legends, in millimetres (multiply by `detail`).
    var currencyLegendSize: CGFloat { usesRoomyKeypad ? 2.3 : 1.45 }

    func rect(_ rect: CGRect) -> CGRect {
        let minY = y(rect.minY)
        return CGRect(x: rect.minX * x, y: minY, width: rect.width * x, height: y(rect.maxY) - minY)
    }
}

extension View {
    /// Sizes and positions a view at a panel rectangle given in millimetres. The parent must be a
    /// top-leading aligned container.
    func placed(at rect: CGRect, scale: PanelScale, alignment: Alignment = .center) -> some View {
        let mapped = scale.rect(rect)
        return frame(width: mapped.width, height: mapped.height, alignment: alignment)
            .offset(x: mapped.minX, y: mapped.minY)
    }
}
