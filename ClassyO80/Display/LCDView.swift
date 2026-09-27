import CalcEngine
import SwiftUI
import UIKit

/// The LCD window: reads the model, exposes the value to accessibility, and offers Copy.
struct LCDView: View {
    let model: CalculatorModel
    let scale: PanelScale

    var body: some View {
        let display = model.display
        let value = LCDLayout.plainValue(of: display)
        LCDGlass(display: display, scale: scale)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 0.8 * scale.detail))
            .contextMenu {
                if display.isOn {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = value
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.spokenLabel(for: display))
            .accessibilityValue(value)
            .accessibilityAddTraits(.updatesFrequently)
            .accessibilityIdentifier("lcd")
    }

    private static func spokenLabel(for display: Display) -> String {
        guard display.isOn else { return "Display, off" }
        let names: [Indicator: String] = [
            .memory: "memory", .error: "error", .constant: "constant", .cost: "cost",
            .sell: "sell", .margin: "margin", .percent: "percent", .exchange: "exchange",
            .rate: "rate", .c1: "C1", .c2: "C2", .c3: "C3", .set: "set",
        ]
        let active = Indicator.allCases.filter { display.indicators.contains($0) }.compactMap { names[$0] }
        return (["Display"] + active).joined(separator: ", ")
    }
}

/// The drawn LCD: window frame, glass, annunciators and eight seven-segment cells.
private struct LCDGlass: View {
    let display: Display
    let scale: PanelScale

    /// Points per millimetre for text, strokes and radii.
    private var mm: CGFloat { scale.detail }
    /// Points per millimetre across and down the window. The LCD sits on the top plate.
    private var mmX: CGFloat { scale.x }
    private var mmY: CGFloat { scale.top }

    // Layout inside the window, in millimetres from its top-left corner.
    private static let firstCellX: CGFloat = 2.0
    private static let cellPitch: CGFloat = 9.55
    private static let cellTop: CGFloat = 4.6
    private static let cellHeight: CGFloat = 15.6
    private static let indicatorTop: CGFloat = 1.05
    private static let indicatorHeight: CGFloat = 2.5

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 0.8 * mm)
                .fill(Palette.lcdFrame)
            RoundedRectangle(cornerRadius: 0.5 * mm)
                .fill(LinearGradient(colors: [Palette.lcdTop, Palette.lcdBottom], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) {
                    // The glass sits below the plate; its top edge catches a soft shadow.
                    LinearGradient(colors: [.black.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 1.4 * mm)
                        .clipShape(RoundedRectangle(cornerRadius: 0.5 * mm))
                }
                .padding(0.45 * mm)

            if display.isOn {
                ZStack(alignment: .topLeading) {
                    indicators
                    digits
                }
                .foregroundStyle(Palette.segment.opacity(0.92))
                .shadow(color: .black.opacity(0.2), radius: 0.12 * mm, x: 0.3 * mm, y: 0.4 * mm)
            }
        }
        .frame(width: Panel.lcd.width * mmX, height: Panel.lcd.height * mmY, alignment: .topLeading)
    }

    private var digits: some View {
        let cells = LCDLayout.cells(for: display.text)
        return ForEach(0..<LCDLayout.digitCount, id: \.self) { index in
            SevenSegmentCell(cell: cells[index])
                .frame(width: Self.cellPitch * mmX, height: Self.cellHeight * mmY)
                .offset(x: (Self.firstCellX + CGFloat(index) * Self.cellPitch) * mmX, y: Self.cellTop * mmY)
        }
    }

    private var indicators: some View {
        ForEach(Annunciator.all, id: \.indicator) { annunciator in
            let isLit = annunciator.indicator == .minus
                ? display.isNegative || display.indicators.contains(.minus)
                : display.indicators.contains(annunciator.indicator)
            annunciatorView(annunciator)
                .frame(height: Self.indicatorHeight * mmY)
                .fixedSize()
                .offset(x: annunciator.x * mmX, y: Self.indicatorTop * mmY)
                .opacity(isLit ? 1 : 0)
        }
    }

    @ViewBuilder
    private func annunciatorView(_ annunciator: Annunciator) -> some View {
        if annunciator.indicator == .minus {
            Rectangle()
                .frame(width: 1.6 * mm, height: 0.6 * mm)
        } else {
            Text(verbatim: annunciator.indicator.rawValue)
                .font(.system(size: 2.55 * mm, weight: .heavy))
                .fontWidth(.condensed)
        }
    }
}

/// Where each annunciator sits along the top of the LCD, in millimetres from the window's left
/// edge. The photo shows −, M and COST; the rest follow the engine's left-to-right order.
private struct Annunciator {
    let indicator: Indicator
    let x: CGFloat

    static let all: [Annunciator] = [
        Annunciator(indicator: .minus, x: 2.1),
        Annunciator(indicator: .memory, x: 4.7),
        Annunciator(indicator: .error, x: 7.5),
        Annunciator(indicator: .constant, x: 9.9),
        Annunciator(indicator: .cost, x: 12.4),
        Annunciator(indicator: .sell, x: 19.3),
        Annunciator(indicator: .margin, x: 26.1),
        Annunciator(indicator: .percent, x: 32.2),
        Annunciator(indicator: .exchange, x: 36.3),
        Annunciator(indicator: .rate, x: 43.7),
        Annunciator(indicator: .c1, x: 51.1),
        Annunciator(indicator: .c2, x: 55.3),
        Annunciator(indicator: .c3, x: 59.5),
        Annunciator(indicator: .set, x: 63.7),
    ]
}
