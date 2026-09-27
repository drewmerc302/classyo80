import SwiftUI

/// Colours sampled from the reference photo, nudged where the photo's lighting washes them out.
enum Palette {
    static let desk = Color(hex: 0x23211F)

    static let rimTop = Color(hex: 0x8C8B8E)
    static let rimBottom = Color(hex: 0x6B6A6D)
    static let rimEdge = Color(hex: 0x4E4D50)
    static let topPlateTop = Color(hex: 0xEEEEEF)
    static let topPlateBottom = Color(hex: 0xD9D9DB)
    static let keyPlate = Color(hex: 0xC4C1C5)
    static let keyPlateShade = Color(hex: 0xB3AFB4)
    static let seamShadow = Color(hex: 0x8F8D91)
    static let seamHighlight = Color(hex: 0xEAE8EC)
    static let lipTop = Color(hex: 0xD8D4D6)
    static let lipBottom = Color(hex: 0xA9A5A7)

    static let print = Color(hex: 0x303134)
    static let solarTop = Color(hex: 0x46312A)
    static let solarBottom = Color(hex: 0x2A1C17)
    static let solarEdge = Color(hex: 0x1B1210)

    static let lcdFrame = Color(hex: 0xA7ABAD)
    static let lcdTop = Color(hex: 0xD2DED8)
    static let lcdBottom = Color(hex: 0xC2D0CA)
    static let segment = Color(hex: 0x1B2120)

    static let legend = Color(hex: 0xF5F5F3)
    static let gold = Color(hex: 0xCDB04A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
