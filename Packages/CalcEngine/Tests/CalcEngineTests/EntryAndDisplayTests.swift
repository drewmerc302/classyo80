import CalcEngine
import Foundation
import Testing

@Suite("Entry and display")
struct EntryAndDisplayTests {
    @Test func freshCalculatorShowsZero() {
        let calc = Calculator()
        #expect(calc.display.isOn)
        #expect(calc.display.text == "0.")
        #expect(!calc.display.isNegative)
        #expect(calc.display.indicators.isEmpty)
    }

    @Test func digitsAppend() {
        var calc = Calculator()
        #expect(calc.run("1 2 3") == "123.")
    }

    @Test func leadingZerosCollapse() {
        var calc = Calculator()
        #expect(calc.run("0 0 0") == "0.")
        #expect(calc.run("7") == "7.")
    }

    @Test func pointStartsFraction() {
        var calc = Calculator()
        #expect(calc.run(".") == "0.")
        #expect(calc.run("5") == "0.5")
    }

    @Test func secondPointIgnored() {
        var calc = Calculator()
        #expect(calc.run("1 . 2 . 3") == "1.23")
    }

    @Test func trailingFractionZerosShowWhileTyping() {
        var calc = Calculator()
        #expect(calc.run("2.50") == "2.50")
        #expect(calc.run("=") == "2.5")
    }

    @Test func entryLimitedToEightDigits() {
        var calc = Calculator()
        #expect(calc.run("123456789") == "12345678.")
    }

    @Test func leadingZeroOfFractionCountsAsDigit() {
        var calc = Calculator()
        #expect(calc.run("0.123456789") == "0.1234567")
    }

    @Test func pointIgnoredWhenEightDigitsTyped() {
        var calc = Calculator()
        #expect(calc.run("12345678 . 9") == "12345678.")
    }

    @Test func resultsAreTruncatedNotRounded() {
        var calc = Calculator()
        #expect(calc.run("2 ÷ 3 =") == "0.6666666")
        #expect(calc.run("AC 1 ÷ 3 × 3 =") == "0.9999999")
    }

    @Test func resultFractionTruncatedToAvailableDigits() {
        var calc = Calculator()
        #expect(calc.run("1000000 ÷ 3 =") == "333333.33")
    }

    @Test func tinyResultTruncatesToZero() {
        var calc = Calculator()
        #expect(calc.run("1 ÷ 50000000 =") == "0.")
        #expect(calc.run("AC 1 ÷ 10000000 =") == "0.0000001")
    }

    @Test func trailingZerosDroppedFromResults() {
        var calc = Calculator()
        #expect(calc.run("1.5 + 1.5 =") == "3.")
    }

    @Test func negativeResultsSetMinusIndicator() {
        var calc = Calculator()
        calc.run("2 − 5 =")
        #expect(calc.display.isNegative)
        #expect(calc.display.text == "3.")
        #expect(calc.display.indicators.contains(.minus))
    }

    @Test func largestValueFits() {
        var calc = Calculator()
        #expect(calc.run("99999998 + 1 =") == "99999999.")
        #expect(!calc.display.indicators.contains(.error))
    }

    @Test func overflowShowsLeadingDigitsShiftedEightPlaces() {
        var calc = Calculator()
        #expect(calc.run("12345678 × 100 =") == "12.345678")
        #expect(calc.display.indicators.contains(.error))
    }

    @Test func negativeOverflowIsAnError() {
        var calc = Calculator()
        calc.run("0 − 99999999 − 2 =")
        #expect(calc.display.indicators.contains(.error))
        #expect(calc.display.isNegative)
    }

    @Test func divisionByZeroIsAnError() {
        var calc = Calculator()
        #expect(calc.run("5 ÷ 0 =") == "0.")
        #expect(calc.display.indicators.contains(.error))
    }

    @Test func errorLocksEverythingButAC() {
        var calc = Calculator()
        calc.run("5 ÷ 0 =")
        calc.run("7 + ▶ +/- MRC M+ M/EX COST %")
        #expect(calc.display.indicators.contains(.error))
        #expect(calc.display.text == "0.")
        calc.run("AC")
        #expect(calc.display.indicators.isEmpty)
    }

    @Test func plusMinusOnEntryThenKeepTyping() {
        var calc = Calculator()
        #expect(calc.run("1 2 +/- 3") == "-123.")
    }

    @Test func plusMinusOnResult() {
        var calc = Calculator()
        #expect(calc.run("2 + 3 = +/-") == "-5.")
        #expect(calc.run("+ 1 =") == "-4.")
    }

    @Test func plusMinusOnZeroStaysPositive() {
        var calc = Calculator()
        calc.run("+/-")
        #expect(!calc.display.isNegative)
    }

    @Test func backspaceToEmptyShowsZero() {
        var calc = Calculator()
        #expect(calc.run("7 ▶") == "0.")
        #expect(calc.run("4") == "4.")
    }

    @Test func backspaceRemovesPointToo() {
        var calc = Calculator()
        #expect(calc.run("1.2 ▶") == "1.")
        #expect(calc.run("▶ 3") == "3.")
    }

    @Test func backspaceIgnoredOnResult() {
        var calc = Calculator()
        #expect(calc.run("12 + 34 = ▶") == "46.")
    }

    @Test func clearEntryOnResultShowsZero() {
        var calc = Calculator()
        #expect(calc.run("2 + 3 = C") == "0.")
    }

    @Test func digitAfterEqualsStartsNewCalculation() {
        var calc = Calculator()
        calc.run("2 + 3 =")
        #expect(calc.run("4 =") == "4.")
    }

    @Test func operatorAfterEqualsContinuesFromResult() {
        var calc = Calculator()
        #expect(calc.run("2 + 3 = × 4 =") == "20.")
    }

    @Test func operatorShowsRunningTotal() {
        var calc = Calculator()
        #expect(calc.run("2 + 3 +") == "5.")
        #expect(calc.run("4 ×") == "9.")
    }

    @Test func equalsWithoutSecondOperandReusesFirst() {
        var calc = Calculator()
        #expect(calc.run("5 × =") == "25.")
        #expect(calc.run("AC 5 + =") == "10.")
    }

    @Test func repeatedEqualsWithoutConstantDoesNothing() {
        var calc = Calculator()
        #expect(calc.run("2 + 3 = = =") == "5.")
    }

    @Test func constantRepeatsOnEquals() {
        var calc = Calculator()
        #expect(calc.run("3 × × =") == "9.")
        #expect(calc.run("=") == "27.")
    }

    @Test func singleOperatorCancelsConstant() {
        var calc = Calculator()
        calc.run("23 + + 12 = ×")
        #expect(!calc.display.indicators.contains(.constant))
        #expect(calc.run("2 =") == "70.")
    }

    @Test func acCancelsConstant() {
        var calc = Calculator()
        calc.run("23 + + AC")
        #expect(!calc.display.indicators.contains(.constant))
    }

    @Test func clearEntryKeepsConstant() {
        var calc = Calculator()
        calc.run("23 + + 12 C")
        #expect(calc.display.indicators.contains(.constant))
        #expect(calc.run("1 =") == "24.")
    }

    @Test func constantPercentMultiply() {
        var calc = Calculator()
        #expect(calc.run("12 × × 5 %") == "0.6")
    }

    @Test func percentWithoutOperatorKeepsValue() {
        var calc = Calculator()
        #expect(calc.run("50 %") == "50.")
    }

    @Test func percentOfResultCanContinue() {
        var calc = Calculator()
        #expect(calc.run("200 × 5 % × 3 =") == "30.")
    }

    @Test func addOnEndsCalculation() {
        var calc = Calculator()
        calc.run("100 × 5 % +")
        #expect(calc.run("7") == "7.")
        #expect(calc.run("=") == "7.")
    }

    @Test func percentChangeFromZeroIsError() {
        var calc = Calculator()
        calc.run("12 − 0 %")
        #expect(calc.display.indicators.contains(.error))
    }

    @Test func markupOfHundredPercentIsError() {
        var calc = Calculator()
        calc.run("120 + 100 %")
        #expect(calc.display.indicators.contains(.error))
    }

    @Test func percentChangeNegative() {
        var calc = Calculator()
        #expect(calc.run("8 − 10 %") == "-20.")
    }
}
