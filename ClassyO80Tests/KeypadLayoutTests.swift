import CalcEngine
import Testing
@testable import ClassyO80

struct KeypadLayoutTests {
    @Test func everyGridSlotIsCoveredExactlyOnce() {
        var covered: [String: Int] = [:]
        for spec in Keypad.keys {
            for row in spec.row..<(spec.row + spec.rowSpan) {
                covered["\(row),\(spec.column)", default: 0] += 1
            }
        }
        for row in 0..<6 {
            for column in 0..<5 {
                #expect(covered["\(row),\(column)"] == 1, "slot row \(row) column \(column)")
            }
        }
        #expect(covered.count == 30)
    }

    @Test func plusIsTheOnlyDoubleHeightKey() {
        let tall = Keypad.keys.filter { $0.rowSpan > 1 }
        #expect(tall.map(\.identifier) == ["key.plus"])
        #expect(tall.first?.row == 4)
        #expect(tall.first?.column == 4)
    }

    @Test func everyEngineKeyHasExactlyOneButton() {
        let expected: [Key] = (0...9).map(Key.digit) + [
            .point, .add, .subtract, .multiply, .divide, .equals, .percent, .plusMinus,
            .backspace, .clear, .allClear, .off, .mrc, .memoryMinus, .memoryPlus,
            .modeToggle, .cost, .sell, .margin,
        ]
        #expect(Keypad.keys.count == expected.count)
        for key in expected {
            #expect(Keypad.keys.filter { $0.key == key }.count == 1, "\(key)")
        }
    }

    @Test func onlyPercentHasAHoldAction() {
        let holdable = Keypad.keys.filter { $0.holdKey != nil }
        #expect(holdable.map(\.key) == [.percent])
        #expect(holdable.first?.holdKey == .set)
    }

    @Test func identifiersAreUniqueAndNamed() {
        let identifiers = Keypad.keys.map(\.identifier)
        #expect(Set(identifiers).count == identifiers.count)
        for identifier in ["key.7", "key.0", "key.plus", "key.equals", "key.AC", "key.C", "key.percent"] {
            #expect(identifiers.contains(identifier), "\(identifier)")
        }
    }

    @Test func spokenLabelsDescribeTheKey() {
        func label(_ key: Key) -> String? { Keypad.keys.first { $0.key == key }?.spokenLabel }
        #expect(label(.mrc) == "memory recall clear")
        #expect(label(.memoryMinus) == "memory minus")
        #expect(label(.plusMinus) == "plus minus")
        #expect(label(.backspace) == "delete last digit")
        #expect(Keypad.keys.allSatisfy { !$0.spokenLabel.isEmpty })
    }
}
