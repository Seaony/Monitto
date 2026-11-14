import SwiftUI

enum MonittoMotion {
    static let press = Animation.easeOut(duration: 0.12)
    static let data = Animation.easeOut(duration: 0.24)
    static let standard = Animation.spring(response: 0.32, dampingFraction: 0.86)
    static let disclosure = Animation.spring(response: 0.3, dampingFraction: 0.9)
    static let navigation = Animation.spring(response: 0.38, dampingFraction: 0.9)
    static let dashboardReflow = Animation.interactiveSpring(
        response: 0.5,
        dampingFraction: 0.92,
        blendDuration: 0.18
    )
    static let dashboardSnap = Animation.spring(
        response: 0.42,
        dampingFraction: 0.95,
        blendDuration: 0.12
    )

    static let pageTransition = AnyTransition.opacity.combined(
        with: .scale(scale: 0.985, anchor: .top)
    )
    static let itemTransition = AnyTransition.opacity.combined(
        with: .scale(scale: 0.96, anchor: .center)
    )
    static let disclosureTransition = AnyTransition.opacity.combined(
        with: .scale(scale: 0.985, anchor: .top)
    )
}

struct MonittoPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var scale = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : scale)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(reduceMotion ? nil : MonittoMotion.press, value: configuration.isPressed)
            .monittoPointingHand()
    }
}

private struct MonittoNumericTransition<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .contentTransition(.numericText())
                .animation(MonittoMotion.data, value: value)
        }
    }
}

private struct MonittoValueAnimation<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value
    let animation: Animation

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    /// `pointerStyle` is scoped to the view, so it cannot leave the cursor stack
    /// unbalanced the way a manual `NSCursor.push()`/`pop()` pair can when a view
    /// disappears while hovered.
    func monittoPointingHand() -> some View {
        pointerStyle(.link)
    }

    func monittoNumericTransition<Value: Equatable>(_ value: Value) -> some View {
        modifier(MonittoNumericTransition(value: value))
    }

    func monittoAnimation<Value: Equatable>(
        _ animation: Animation = MonittoMotion.standard,
        value: Value
    ) -> some View {
        modifier(MonittoValueAnimation(value: value, animation: animation))
    }
}
