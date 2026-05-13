import SwiftUI

struct ConfirmationPanel: View {
    let request: ConfirmationRequest
    let onAnswer: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(localized("confirmation_title"))
                .font(.headline)

            Text(request.question)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(request.options, id: \.self) { option in
                    Button(action: {
                        HapticEngine.shared.selectionChanged()
                        onAnswer(option)
                    }) {
                        Text(option)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(action: { onAnswer("") }) {
                    Text(localized("confirmation_cancel"))
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(12)
        )
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
