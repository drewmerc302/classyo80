import UIKit

/// The tap felt on every key press.
@MainActor
protocol KeyHaptics {
    func keyPressed()
}

@MainActor
final class ImpactHaptics: KeyHaptics {
    private let generator = UIImpactFeedbackGenerator(style: .light)

    func keyPressed() {
        generator.impactOccurred()
    }
}
