import CoreGraphics
import Testing
@testable import ClassyO80

struct PanelScaleTests {
    private func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.001 }

    @Test func exactAspectIsUniform() {
        let scale = PanelScale(fitting: CGSize(width: 103 * 4, height: 147 * 4))
        #expect(close(scale.detail, 4))
        #expect(close(scale.x, 4))
        #expect(close(scale.top, 4))
        #expect(close(scale.keypad, 4))
        #expect(close(scale.size.width, 412))
        #expect(close(scale.size.height, 588))
    }

    @Test func phonePortraitFillsWidthAndHeight() {
        let available = CGSize(width: 386, height: 766)
        let scale = PanelScale(fitting: available)
        #expect(close(scale.size.width, available.width))
        #expect(close(scale.size.height, available.height))
        #expect(close(scale.detail, available.width / 103))
    }

    @Test func extraHeightGoesMostlyToTheKeypad() {
        let scale = PanelScale(fitting: CGSize(width: 386, height: 766))
        #expect(scale.top <= scale.detail * PanelScale.maxTopStretch + 0.001)
        #expect(scale.keypad > scale.top)
    }

    @Test func bottomLipKeepsItsRealThickness() {
        let scale = PanelScale(fitting: CGSize(width: 386, height: 766))
        let lip = scale.y(Panel.size.height) - scale.y(Panel.lipY)
        #expect(close(lip, (Panel.size.height - Panel.lipY) * scale.detail))
    }

    @Test func verticalMapIsContinuousAndIncreasing() {
        let scale = PanelScale(fitting: CGSize(width: 386, height: 766))
        #expect(close(scale.y(0), 0))
        #expect(close(scale.y(Panel.seamY), Panel.seamY * scale.top))
        var previous: CGFloat = -1
        for step in 0...147 {
            let y = scale.y(CGFloat(step))
            #expect(y > previous)
            previous = y
        }
    }

    @Test func landscapeStretchesWidthOnlyUpToTheCap() {
        let available = CGSize(width: 1354, height: 990)
        let scale = PanelScale(fitting: available)
        #expect(close(scale.size.height, available.height))
        #expect(close(scale.x, scale.detail * PanelScale.maxWidthStretch))
        #expect(scale.size.width < available.width)
    }

    @Test func veryTallScreensCapTheStretch() {
        let scale = PanelScale(fitting: CGSize(width: 300, height: 1200))
        #expect(close(scale.size.height, 147 * scale.detail * PanelScale.maxHeightStretch))
        #expect(close(scale.size.width, 300))
    }

    // Roomy keypad: tall phone layouts open the gap under the top row and shorten the other caps.

    @Test func phoneUsesRoomyKeypadButExactAspectDoesNot() {
        #expect(PanelScale(fitting: CGSize(width: 386, height: 766)).usesRoomyKeypad)
        #expect(PanelScale(fitting: CGSize(width: 359, height: 631)).usesRoomyKeypad)
        #expect(!PanelScale(fitting: CGSize(width: 103 * 4, height: 147 * 4)).usesRoomyKeypad)
        #expect(!PanelScale(fitting: CGSize(width: 1000, height: 1310)).usesRoomyKeypad)
    }

    @Test func roomyKeypadLiftsOnlyTheTopRow() {
        let roomy = PanelScale(fitting: CGSize(width: 386, height: 766))
        let lifted = roomy.keyRect(row: 0, column: 2)
        #expect(close(lifted.minY, Panel.keyRect(row: 0, column: 2).minY - PanelScale.topRowLift))
        #expect(roomy.keyRect(row: 1, column: 2) == Panel.keyRect(row: 1, column: 2))
        #expect(roomy.keyRect(row: 4, column: 4, rowSpan: 2) == Panel.keyRect(row: 4, column: 4, rowSpan: 2))
        #expect(lifted.minY - Panel.touchSlop > Panel.seamY)

        let plain = PanelScale(fitting: CGSize(width: 103 * 4, height: 147 * 4))
        #expect(plain.keyRect(row: 0, column: 2) == Panel.keyRect(row: 0, column: 2))
    }

    @Test func roomyKeypadShortensCapsTenPercentBelowTheTopRow() {
        let roomy = PanelScale(fitting: CGSize(width: 386, height: 766))
        #expect(close(roomy.capInset(row: 0), 0))
        for row in 1...5 {
            #expect(close(roomy.capInset(row: row), Panel.keyHeight * 0.05), "row \(row)")
        }
        let plain = PanelScale(fitting: CGSize(width: 103 * 4, height: 147 * 4))
        #expect(close(plain.capInset(row: 3), 0))
    }

    @Test func currencyLegendsSitCentredInTheWiderGapAndGrow() {
        let roomy = PanelScale(fitting: CGSize(width: 386, height: 766))
        let gapTop = roomy.keyRect(row: 0, column: 0).maxY
        let gapBottom = roomy.keyRect(row: 1, column: 0).minY
        #expect(close(roomy.currencyLegendY, (gapTop + gapBottom) / 2))
        #expect(gapBottom - gapTop > (Panel.rowY[1] - Panel.rowY[0] - Panel.smallKeyHeight) + 1.9)

        let plain = PanelScale(fitting: CGSize(width: 103 * 4, height: 147 * 4))
        #expect(roomy.currencyLegendSize > plain.currencyLegendSize * 1.5)
    }

    @Test func rectMapsThroughBothAxes() {
        let scale = PanelScale(fitting: CGSize(width: 386, height: 766))
        let key = Panel.keyRect(row: 5, column: 0)
        let mapped = scale.rect(key)
        #expect(close(mapped.minX, key.minX * scale.x))
        #expect(close(mapped.width, key.width * scale.x))
        #expect(close(mapped.minY, scale.y(key.minY)))
        #expect(close(mapped.height, key.height * scale.keypad))
        #expect(mapped.maxY <= scale.y(Panel.lipY))
    }
}
