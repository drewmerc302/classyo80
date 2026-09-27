import SwiftUI

@main
struct ClassyO80App: App {
    @State private var model = Self.makeModel()

    var body: some Scene {
        WindowGroup {
            CalculatorScreen(model: model)
        }
    }

    /// UI tests launch with `--uitesting` so they start from a clean, throwaway store.
    private static func makeModel() -> CalculatorModel {
        let arguments = ProcessInfo.processInfo.arguments
        let model: CalculatorModel
        if arguments.contains("--uitesting") {
            let suiteName = "ClassyO80UITests"
            let defaults = UserDefaults(suiteName: suiteName) ?? .standard
            defaults.removePersistentDomain(forName: suiteName)
            model = CalculatorModel(defaults: defaults)
        } else {
            model = CalculatorModel()
        }
        #if DEBUG
        pressLaunchKeys(arguments, into: model)
        #endif
        return model
    }

    #if DEBUG
    /// Screenshot helper: `--keys "1 Mplus AC 7 point 5"` presses those keys (accessibility
    /// identifiers without the `key.` prefix) once at launch.
    private static func pressLaunchKeys(_ arguments: [String], into model: CalculatorModel) {
        guard let flag = arguments.firstIndex(of: "--keys"), arguments.indices.contains(flag + 1) else { return }
        for name in arguments[flag + 1].split(separator: " ") {
            if let spec = Keypad.keys.first(where: { $0.identifier == "key.\(name)" }) {
                model.press(spec.key)
            }
        }
    }
    #endif
}
