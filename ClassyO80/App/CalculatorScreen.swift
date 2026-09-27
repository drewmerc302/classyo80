import SwiftUI

/// The calculator stretched to fill the screen on a dark desk, with hardware keyboard input.
///
/// Printable keys arrive through `onKeyPress` on the focused root. Return, Escape and Delete never
/// reach it, so the =, AC and ▶ buttons carry those as keyboard shortcuts (see `HardwareKeyboard`).
struct CalculatorScreen: View {
    let model: CalculatorModel

    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        GeometryReader { proxy in
            CalculatorBody(model: model, scale: PanelScale(fitting: proxy.size))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .padding(8)
        .background(Palette.desk.ignoresSafeArea())
        .focusable(interactions: .edit)
        .focused($hasKeyboardFocus)
        .focusEffectDisabled()
        .onKeyPress(phases: .down, action: handleKeyPress)
        .defaultFocus($hasKeyboardFocus, true)
        // Focus requested in onAppear does not take; ask again once the view is in a window.
        .task { hasKeyboardFocus = true }
        .preferredColorScheme(.dark)
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard let key = HardwareKeyboard.key(for: press.characters, modifiers: press.modifiers) else {
            return .ignored
        }
        model.press(key)
        return .handled
    }
}
