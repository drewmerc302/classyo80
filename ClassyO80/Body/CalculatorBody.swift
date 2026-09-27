import SwiftUI

/// The whole calculator at a given scale: shell, top-plate printing, LCD and keypad.
struct CalculatorBody: View {
    let model: CalculatorModel
    let scale: PanelScale

    var body: some View {
        ZStack(alignment: .topLeading) {
            Shell(scale: scale)
            TopPlatePrinting(scale: scale)
            LCDView(model: model, scale: scale)
                .placed(at: Panel.lcd, scale: scale)
            KeypadView(scale: scale) { model.press($0) }
        }
        .frame(width: scale.size.width, height: scale.size.height, alignment: .topLeading)
    }
}

/// Dark rim, smooth top plate, brushed keypad plate and the bevelled bottom lip.
private struct Shell: View {
    let scale: PanelScale
    private var mm: CGFloat { scale.detail }

    var body: some View {
        let plateWidth = Panel.size.width - 2 * Panel.rim
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Panel.cornerRadius * mm, style: .continuous)
                .fill(LinearGradient(colors: [Palette.rimTop, Palette.rimBottom], startPoint: .top, endPoint: .bottom))
                .overlay {
                    RoundedRectangle(cornerRadius: Panel.cornerRadius * mm, style: .continuous)
                        .strokeBorder(Palette.rimEdge, lineWidth: 0.3 * mm)
                }
                .shadow(color: .black.opacity(0.55), radius: 3 * mm, y: 1.5 * mm)
                .frame(width: scale.size.width, height: scale.size.height)

            UnevenRoundedRectangle(
                topLeadingRadius: (Panel.cornerRadius - 1.2) * mm,
                topTrailingRadius: (Panel.cornerRadius - 1.2) * mm,
                style: .continuous
            )
            .fill(LinearGradient(colors: [Palette.topPlateTop, Palette.topPlateBottom], startPoint: .top, endPoint: .bottom))
            .placed(at: CGRect(x: Panel.rim, y: 2.0, width: plateWidth, height: Panel.seamY - 2.0), scale: scale)

            ZStack {
                LinearGradient(colors: [Palette.keyPlate, Palette.keyPlateShade], startPoint: .top, endPoint: .bottom)
                BrushedMetal(mm: mm)
            }
            .placed(at: CGRect(x: Panel.rim, y: Panel.seamY, width: plateWidth, height: Panel.lipY - Panel.seamY), scale: scale)

            VStack(spacing: 0) {
                Palette.seamShadow.frame(height: 0.35 * mm)
                Palette.seamHighlight.frame(height: 0.25 * mm)
            }
            .placed(at: CGRect(x: Panel.rim, y: Panel.seamY - 0.2, width: plateWidth, height: 0.6), scale: scale)

            UnevenRoundedRectangle(
                bottomLeadingRadius: (Panel.cornerRadius - 1.5) * mm,
                bottomTrailingRadius: (Panel.cornerRadius - 1.5) * mm,
                style: .continuous
            )
            .fill(LinearGradient(colors: [Palette.lipTop, Palette.lipBottom], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) { Palette.seamShadow.frame(height: 0.3 * mm) }
            .placed(at: CGRect(x: Panel.rim, y: Panel.lipY, width: plateWidth, height: Panel.lipBottom - Panel.lipY), scale: scale)
        }
        .accessibilityHidden(true)
    }
}

/// Vertical hairline streaks like the real unit's brushed aluminium keypad plate.
private struct BrushedMetal: View {
    let mm: CGFloat

    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x80B
            func random() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 33) / Double(1 << 31)
            }
            var x: CGFloat = 0
            while x < size.width {
                let width = CGFloat(0.08 + random() * 0.3) * mm
                let shade: Color = random() < 0.5 ? .white : .black
                let rect = CGRect(x: x, y: 0, width: width, height: size.height)
                context.fill(Path(rect), with: .color(shade.opacity(0.012 + random() * 0.045)))
                x += width + CGFloat(random() * 0.25) * mm
            }
        }
    }
}

/// The wordmark, the solar cell and the model name.
private struct TopPlatePrinting: View {
    let scale: PanelScale
    private var mm: CGFloat { scale.detail }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(verbatim: Panel.brandName)
                .font(.system(size: 4.6 * mm, weight: .heavy))
                .fontWidth(.expanded)
                .kerning(0.15 * mm)
                .foregroundStyle(Palette.print)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .placed(at: Panel.brand, scale: scale, alignment: .leading)

            RoundedRectangle(cornerRadius: 0.5 * mm)
                .fill(LinearGradient(colors: [Palette.solarTop, Palette.solarBottom], startPoint: .top, endPoint: .bottom))
                .overlay {
                    LinearGradient(colors: [.white.opacity(0.07), .clear], startPoint: .topLeading, endPoint: .center)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 0.5 * mm)
                        .strokeBorder(Palette.solarEdge, lineWidth: 0.3 * mm)
                }
                .placed(at: Panel.solarPanel, scale: scale)

            Text(verbatim: Panel.modelName)
                .font(.system(size: 3.2 * mm, weight: .semibold))
                .foregroundStyle(Palette.print)
                .fixedSize()
                .placed(at: Panel.model, scale: scale, alignment: .leading)
        }
        .accessibilityHidden(true)
    }
}
