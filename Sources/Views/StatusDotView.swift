import SwiftUI

struct StatusDotView: View {
    let color: Color
    let breathing: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                if breathing {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 1.4
                        opacity = 0.5
                    }
                }
            }
            .onChange(of: breathing) { newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 1.4
                        opacity = 0.5
                    }
                } else {
                    withAnimation(.default) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
            }
    }
}
