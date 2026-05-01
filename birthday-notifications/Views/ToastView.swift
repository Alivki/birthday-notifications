import SwiftUI

struct ToastView: View {
    @Binding var message: String?
    @State private var displayedMessage: String?
    @State private var isVisible = false

    var body: some View {
        Group {
            if let displayedMessage, isVisible {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    Text(displayedMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(
                    Capsule()
                        .fill(.regularMaterial)
                )
                .overlay(
                    Capsule()
                        .stroke(.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.15), value: isVisible)
        .onChange(of: message) {
            guard let msg = message else { return }
            displayedMessage = msg
            withAnimation { isVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { isVisible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.message = nil
                    self.displayedMessage = nil
                }
            }
        }
    }
}
