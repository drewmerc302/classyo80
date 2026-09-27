import CalcEngine

/// Decides what a key sends when it can be tapped or held (only `%`, which sends `.set` when held).
///
/// A SwiftUI `Button` reports three things: the press starting, the press ending, and the action
/// (touch up inside). The last two can arrive in either order, so a hold is remembered until the
/// next press begins and swallows the activation that follows it.
struct KeyHoldTracker: Equatable {
    static let holdDuration: Duration = .milliseconds(800)

    let tapKey: Key
    let holdKey: Key?
    private var isPressed = false
    private var holdFired = false

    init(tapKey: Key, holdKey: Key? = nil) {
        self.tapKey = tapKey
        self.holdKey = holdKey
    }

    /// A finger went down. Returns true when the caller should start a hold timer.
    mutating func pressBegan() -> Bool {
        isPressed = true
        holdFired = false
        return holdKey != nil
    }

    mutating func pressEnded() {
        isPressed = false
    }

    /// The hold timer ran out. Returns the hold key if the finger is still down and it has not
    /// already been sent for this press.
    mutating func holdElapsed() -> Key? {
        guard isPressed, !holdFired, let holdKey else { return nil }
        holdFired = true
        return holdKey
    }

    /// The button fired (touch up inside). Returns the key to send, or nil after a hold.
    mutating func activated() -> Key? {
        holdFired ? nil : tapKey
    }
}
