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
                        .font(.title3)
                    Text(displayedMessage)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
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
