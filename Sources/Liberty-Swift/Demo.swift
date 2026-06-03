import SwiftUI

struct FrameDemo: View {
  @State private var prompt: String = ""
  @State private var chatWindowEmpty: Bool = true
  @State private var isSendButtonHovered: Bool = false

  @State private var isSendButtonDisabled: Bool = true

  private var scaleFactor = 1.2
  private var animationDelay = 0.25
  var body: some View {
    VStack(spacing: 12) {

      if !chatWindowEmpty {
        Spacer()
      }
      HStack(alignment: .bottom, spacing: 12) {
        TextEditor(text: $prompt)
          .font(.body)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 6)
          .padding(.vertical, 15)
          .frame(minHeight: 30, maxHeight: 100)
          .frame(width: prompt.isEmpty ? 400 : nil)
          .fixedSize(horizontal: false, vertical: true)
          .background(.regularMaterial)
          .cornerRadius(6)
          // Make RETURN send prompt, SHIFT+RETURN insert a newline
          .onKeyPress(keys: [.return], phases: .down) { keyPress in
            if keyPress.modifiers.contains(.shift) {
              return .ignored
            }
            guard !prompt.isEmpty else { return .handled }
            prompt.removeAll()
            chatWindowEmpty = false
            return .handled
          }
          .overlay(alignment: .topLeading) {
            if prompt.isEmpty {
              Text("Enter prompt")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 15)
                .allowsHitTesting(false)
            }
          }
        Button {
          prompt.removeAll()
          chatWindowEmpty = false
        } label: {
          Image(systemName: "arrow.up")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .disabled(isSendButtonDisabled)
        .buttonStyle(.plain)
        .frame(
          width: isSendButtonHovered ? 48 * scaleFactor : 48,
          height: isSendButtonHovered ? 45 * scaleFactor : 45
        )
        .background(.regularMaterial)
        .cornerRadius(6)
        .onHover { hover in
          isSendButtonHovered = hover && !isSendButtonDisabled
        }
        .animation(.spring(duration: animationDelay), value: isSendButtonHovered)
      }
      .onChange(of: prompt) {
        isSendButtonDisabled = prompt.isEmpty
      }
      .padding(.bottom, 12)
      .animation(.spring(duration: animationDelay + 0.25), value: prompt.isEmpty)
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .frame(minWidth: 400, minHeight: 200)
    .background(
      LinearGradient(colors: [.indigo, .mint], startPoint: .topLeading, endPoint: .bottom)
    )
    .animation(.spring(duration: animationDelay), value: isSendButtonHovered)
    .safeAreaInset(edge: .leading) {
      VStack {
        Image(systemName: "line.3.horizontal")
        Spacer()
        Image(systemName: "gearshape")
      }
      .padding()
      .background(.regularMaterial)
    }
  }
}
