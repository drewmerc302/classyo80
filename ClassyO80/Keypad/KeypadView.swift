import CalcEngine
import SwiftUI

/// All thirty keys at their measured positions, plus the legends printed on the plate around them.
struct KeypadView: View {
    let scale: PanelScale
    let onPress: (Key) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            printedLegends
            ForEach(Keypad.keys) { spec in
                KeyButton(spec: spec, scale: scale, onPress: onPress)
                    .placed(
                        at: scale.keyRect(row: spec.row, column: spec.column, rowSpan: spec.rowSpan)
                            .insetBy(dx: -Panel.touchSlop, dy: -Panel.touchSlop),
                        scale: scale
                    )
            }
        }
        .frame(width: scale.size.width, height: scale.size.height, alignment: .topLeading)
    }

    /// C3, C2 and C1 above the memory keys (their Conversion-mode meanings) and ON beside AC.
    private var printedLegends: some View {
        let mm = scale.detail
        return ZStack(alignment: .topLeading) {
            ForEach(Array(["C3", "C2", "C1"].enumerated()), id: \.element) { column, legend in
                Text(verbatim: legend)
                    .font(.system(size: scale.currencyLegendSize * mm, weight: .medium))
                    .placed(
                        at: CGRect(x: Panel.columnX[column], y: scale.currencyLegendY - 1.5, width: Panel.keyWidth, height: 3.0),
                        scale: scale
                    )
            }
            Text(verbatim: "ON")
                .font(.system(size: 1.9 * mm, weight: .bold))
                .placed(
                    at: CGRect(x: 2.6, y: Panel.rowY[5] + Panel.keyHeight / 2 - 1.5, width: 5.4, height: 3),
                    scale: scale
                )
        }
        .foregroundStyle(Palette.print)
        .accessibilityHidden(true)
    }
}
