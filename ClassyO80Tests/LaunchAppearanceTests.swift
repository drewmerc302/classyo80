import SwiftUI
import Testing
import UIKit
@testable import ClassyO80

/// The generated launch screen paints the `LaunchBackground` asset before any SwiftUI view exists,
/// so that asset has to stay in step with `Palette.desk`. If it drifts, every cold start flashes
/// the wrong colour behind the calculator.
@MainActor
struct LaunchAppearanceTests {
    @Test func launchBackgroundMatchesTheDesk() throws {
        let asset = try #require(UIColor(named: "LaunchBackground"), "LaunchBackground is missing")
        #expect(components(of: asset) == components(of: UIColor(Palette.desk)))
    }

    /// Rounded to the 8 bits the asset catalogue stores.
    private func components(of color: UIColor) -> [Int] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
    }
}
