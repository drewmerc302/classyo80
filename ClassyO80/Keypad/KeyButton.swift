import CalcEngine
import SwiftUI

/// One key. A real `Button`, so it fires on touch up inside and gets the platform's
/// accessibility behavior; a key with a hold action (%) also watches how long it is held.
struct KeyButton: View {
    let spec: KeySpec
    let scale: PanelScale
    let onPress: (Key) -> Void

    @State private var tracker: KeyHoldTracker
    @State private var holdTimer: Task<Void, Never>?

    init(spec: KeySpec, scale: PanelScale, onPress: @escaping (Key) -> Void) {
        self.spec = spec
        self.scale = scale
        self.onPress = onPress
        _tracker = State(initialValue: KeyHoldTracker(tapKey: spec.key, holdKey: spec.holdKey))
    }

    var body: some View {
        Button {
            if let key = tracker.activated() { onPress(key) }
        } label: {
            KeyLegendView(spec: spec, mm: scale.detail)
        }
        .buttonStyle(KeyCapStyle(style: spec.style, mm: scale.detail, slop: touchSlop, onPressChange: pressChanged))
        .keyboardShortcut(HardwareKeyboard.shortcut(for: spec.key))
        .accessibilityLabel(spec.spokenLabel)
        .accessibilityIdentifier(spec.identifier)
        .accessibilityActions {
            if let holdKey = spec.holdKey {
                Button("Hold for set") { onPress(holdKey) }
            }
        }
    }

    /// Padding between the touch area and the visible cap: the keypad's invisible touch margin,
    /// plus the cap trim of the roomy keypad above and below.
    private var touchSlop: EdgeInsets {
        let vertical = (Panel.touchSlop + scale.capInset(row: spec.row)) * scale.keypad
        let horizontal = Panel.touchSlop * scale.x
        return EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    private func pressChanged(_ isPressed: Bool) {
        holdTimer?.cancel()
        holdTimer = nil
        guard isPressed else {
            tracker.pressEnded()
            return
        }
        guard tracker.pressBegan() else { return }
        holdTimer = Task {
            do {
                try await Task.sleep(for: KeyHoldTracker.holdDuration)
            } catch {
                return
            }
            if let key = tracker.holdElapsed() { onPress(key) }
        }
    }
}

/// Draws the key cap and reports press changes so holds can be timed.
private struct KeyCapStyle: ButtonStyle {
    let style: KeySpec.Style
    let mm: CGFloat
    let slop: EdgeInsets
    let onPressChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        KeyCap(style: style, isPressed: configuration.isPressed, mm: mm, slop: slop) {
            configuration.label
        }
        .onChange(of: configuration.isPressed) { _, isPressed in
            onPressChange(isPressed)
        }
    }
}

private struct KeyCap<Label: View>: View {
    let style: KeySpec.Style
    let isPressed: Bool
    let mm: CGFloat
    let slop: EdgeInsets
    @ViewBuilder let label: Label

    var body: some View {
        let colors = KeyColors(style)
        let radius = (style == .small ? 2.0 : 2.5) * mm
        ZStack {
            // The dark skirt around the key cap.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(colors.skirt)
                .shadow(color: .black.opacity(isPressed ? 0.18 : 0.32), radius: 0.45 * mm, y: (isPressed ? 0.15 : 0.45) * mm)
            RoundedRectangle(cornerRadius: radius * 0.8, style: .continuous)
                .fill(LinearGradient(colors: [colors.faceTop, colors.faceBottom], startPoint: .top, endPoint: .bottom))
                .overlay {
                    RoundedRectangle(cornerRadius: radius * 0.8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.02)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 0.22 * mm
                        )
                }
                .padding(EdgeInsets(top: 0.4 * mm, leading: 0.5 * mm, bottom: 0.8 * mm, trailing: 0.5 * mm))
            label
                .foregroundStyle(Palette.legend)
                .offset(y: -0.25 * mm)
        }
        .brightness(isPressed ? -0.08 : 0)
        .scaleEffect(isPressed ? 0.965 : 1)
        .animation(.easeOut(duration: 0.05), value: isPressed)
        .padding(slop)
        .contentShape(Rectangle())
    }
}

private struct KeyColors {
    let skirt: Color
    let faceTop: Color
    let faceBottom: Color

    init(_ style: KeySpec.Style) {
        switch style {
        case .small:
            skirt = Color(hex: 0x3C3B3F); faceTop = Color(hex: 0x6D6C71); faceBottom = Color(hex: 0x58575C)
        case .function:
            skirt = Color(hex: 0x3A393D); faceTop = Color(hex: 0x6E6C71); faceBottom = Color(hex: 0x5A585D)
        case .digit:
            skirt = Color(hex: 0x1E1D20); faceTop = Color(hex: 0x47454A); faceBottom = Color(hex: 0x363439)
        case .clear:
            skirt = Color(hex: 0x9E4A22); faceTop = Color(hex: 0xF28E57); faceBottom = Color(hex: 0xDB6E3A)
        }
    }
}

/// The legend printed on a key cap.
private struct KeyLegendView: View {
    let spec: KeySpec
    let mm: CGFloat

    var body: some View {
        switch spec.legend {
        case let .text(text, size):
            VStack(spacing: -0.2 * mm) {
                if let caption = spec.caption {
                    Text(verbatim: caption)
                        .font(.system(size: 1.75 * mm, weight: .semibold))
                }
                Text(verbatim: text)
                    .font(.system(size: size * mm, weight: spec.style == .digit ? .regular : .medium))
            }
        case let .gold(text):
            Text(verbatim: text)
                .font(.system(size: 2.7 * mm, weight: .semibold))
                .foregroundStyle(Palette.gold)
        case .play:
            PlayTriangle()
                .frame(width: 3.2 * mm, height: 2.5 * mm)
        case .plusMinus:
            ZStack {
                Text(verbatim: "+").offset(x: -1.2 * mm, y: -0.9 * mm)
                Text(verbatim: "/").font(.system(size: 3.8 * mm, weight: .light))
                Text(verbatim: "−").offset(x: 1.3 * mm, y: 1.1 * mm)
            }
            .font(.system(size: 3.6 * mm, weight: .regular))
        case .dot:
            Circle()
                .frame(width: 1.15 * mm, height: 1.15 * mm)
        }
    }
}

private struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
