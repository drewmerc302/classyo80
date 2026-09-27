import CalcEngine
import Testing
@testable import ClassyO80

private let blank = LCDCell.blank

private func d(_ digit: Character, point: Bool = false, separator: Bool = false) -> LCDCell {
    LCDCell(digit: digit, hasPoint: point, hasSeparator: separator)
}

private func blanks(_ count: Int) -> [LCDCell] {
    Array(repeating: blank, count: count)
}

struct LCDLayoutTests {
    @Test func zeroShowsOnlyTheLastCellWithItsPoint() {
        #expect(LCDLayout.cells(for: "0.") == blanks(7) + [d("0", point: true)])
    }

    @Test func integerIsRightAlignedWithTrailingPoint() {
        #expect(LCDLayout.cells(for: "35.") == blanks(6) + [d("3"), d("5", point: true)])
    }

    @Test func pointSitsAfterTheIntegerPart() {
        #expect(LCDLayout.cells(for: "11.4") == blanks(5) + [d("1"), d("1", point: true), d("4")])
    }

    @Test func separatorsGroupTheIntegerPartInThrees() {
        #expect(LCDLayout.cells(for: "1234567.8") == [
            d("1", separator: true), d("2"), d("3"), d("4", separator: true),
            d("5"), d("6"), d("7", point: true), d("8"),
        ])
    }

    @Test func eightDigitIntegerFillsEveryCell() {
        #expect(LCDLayout.cells(for: "12345678.") == [
            d("1"), d("2", separator: true), d("3"), d("4"),
            d("5", separator: true), d("6"), d("7"), d("8", point: true),
        ])
    }

    @Test func fourDigitIntegerHasOneSeparator() {
        #expect(LCDLayout.cells(for: "1234.") == blanks(4) + [
            d("1", separator: true), d("2"), d("3"), d("4", point: true),
        ])
    }

    @Test func leadingZeroOfAFractionTakesACell() {
        #expect(LCDLayout.cells(for: "0.0000001") == [
            d("0", point: true), d("0"), d("0"), d("0"), d("0"), d("0"), d("0"), d("1"),
        ])
    }

    @Test func trailingZeroIsKept() {
        #expect(LCDLayout.cells(for: "2.50") == blanks(5) + [d("2", point: true), d("5"), d("0")])
    }

    @Test func fractionDigitsNeverGetSeparators() {
        #expect(LCDLayout.cells(for: "110.80332") == [
            d("1"), d("1"), d("0", point: true), d("8"), d("0"), d("3"), d("3"), d("2"),
        ])
    }

    @Test func emptyTextIsABlankDisplay() {
        #expect(LCDLayout.cells(for: "") == blanks(8))
    }

    @Test func alwaysEightCells() {
        for text in ["0.", "35.", "12345678.", "0.0000001", ""] {
            #expect(LCDLayout.cells(for: text).count == 8)
        }
    }
}

struct DisplayValueTests {
    private func display(_ text: String, negative: Bool = false, on: Bool = true) -> Display {
        Display(isOn: on, text: text, isNegative: negative, indicators: [])
    }

    @Test func dropsTheTrailingPointOfAnInteger() {
        #expect(LCDLayout.plainValue(of: display("35.")) == "35")
        #expect(LCDLayout.plainValue(of: display("0.")) == "0")
    }

    @Test func keepsFractionDigitsAsShown() {
        #expect(LCDLayout.plainValue(of: display("11.4")) == "11.4")
        #expect(LCDLayout.plainValue(of: display("2.50")) == "2.50")
    }

    @Test func negativeValuesGetAMinusSign() {
        #expect(LCDLayout.plainValue(of: display("6.", negative: true)) == "-6")
    }

    @Test func offDisplayHasNoValue() {
        #expect(LCDLayout.plainValue(of: display("", on: false)) == "")
    }
}
