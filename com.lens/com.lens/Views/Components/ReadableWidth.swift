import SwiftUI

private struct ReadableWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    func readableWidth(_ maxWidth: CGFloat = 720) -> some View {
        modifier(ReadableWidthModifier(maxWidth: maxWidth))
    }
}
