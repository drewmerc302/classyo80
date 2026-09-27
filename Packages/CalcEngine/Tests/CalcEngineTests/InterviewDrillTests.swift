import CalcEngine
import Testing

/// Keystrokes from case-interview percent drills and a percent worksheet written for this
/// exact calculator.
@Suite("Interview drill keystrokes")
struct InterviewDrillTests {
    @Test func percentOverTestFromDrills() {
        var calc = Calculator()
        #expect(calc.run("160 − 120 %") == "33.333333")
    }

    @Test func percentOverOrUnder() {
        var calc = Calculator()
        #expect(calc.run("47700 − 30000 %") == "59.")
    }

    @Test func chainStraightFromTheMath() {
        var calc = Calculator()
        #expect(calc.run("21 × 1700 + 12000 =") == "47700.")
        #expect(calc.run("− 30000 %") == "59.")
    }

    @Test func aAsPercentOfB() {
        var calc = Calculator()
        #expect(calc.run("17700 ÷ 30000 %") == "59.")
    }

    @Test func fallbackDivision() {
        var calc = Calculator()
        #expect(calc.run("17700 ÷ 30000 =") == "0.59")
    }

    @Test func percentUnderBudget() {
        var calc = Calculator()
        #expect(calc.run("24000 − 30000 %") == "-20.")
    }

    @Test func newAmountAfterPercentIncrease() {
        var calc = Calculator()
        #expect(calc.run("100 + 15 = × 200 %") == "230.")
    }

    @Test func newAmountAfterPercentDecrease() {
        var calc = Calculator()
        #expect(calc.run("100 − 15 = × 200 %") == "170.")
    }

    @Test func findTheWhole() {
        var calc = Calculator()
        // 45 is 30% of what? a ÷ b %: 45 ÷ 30 % = 150.
        #expect(calc.run("45 ÷ 30 %") == "150.")
    }
}
