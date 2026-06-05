import SwiftUI

struct MainWindow: View {
  @State private var prompt: String = ""
  @State private var chatWindowEmpty: Bool = true
  @State private var isSendButtonHovered: Bool = false

  @State private var isSendButtonDisabled: Bool = true

  @State private var userMessagesList: [String] = []
  @State private var llmResponseList: [String] = []

  private var scaleFactor = 1.2
  private var animationDelay = 0.25
  var body: some View {
    VStack(spacing: 12) {
      if !chatWindowEmpty {
        Spacer()
        ScrollView {
          ForEach(userMessagesList.indices, id: \.self) { index in
            UserMessageView(userMessagesList[index])
          }
          ForEach(llmResponseList.indices, id: \.self) { index in
            Text(llmResponseList[index])
          }
        }
      }
      GlassEffectContainer {
        HStack(alignment: .bottom, spacing: 12) {
          TextEditor(text: $prompt)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 6)
            .padding(.vertical, 15)
            .frame(minHeight: 30, maxHeight: 100)
            .frame(width: prompt.isEmpty ? 400 : 750)
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .topLeading) {
              if prompt.isEmpty {
                Text("Enter prompt")
                  .font(.body)
                  .foregroundColor(Color(nsColor: .placeholderTextColor))
                  .padding(.horizontal, 10)
                  .padding(.vertical, 14)
                  .allowsHitTesting(false)
              }
            }
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 6))
            .onKeyPress(keys: [.return], phases: .down) { keyPress in
              if keyPress.modifiers.contains(.shift) {
                return .ignored
              }
              guard !prompt.isEmpty else { return .handled }
              userMessagesList.append(prompt)
              prompt.removeAll()
              chatWindowEmpty = false
              return .handled
            }
          Button {
            userMessagesList.append(prompt)
            prompt.removeAll()
            chatWindowEmpty = false
          } label: {
            Image(systemName: "arrow.up")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .contentShape(Rectangle())
          }
          .disabled(isSendButtonDisabled)
          .buttonStyle(.glass)
          .frame(
            width: isSendButtonHovered ? 48 * scaleFactor : 48,
            height: isSendButtonHovered ? 45 * scaleFactor : 45
          )
          .onHover { hover in
            isSendButtonHovered = hover && !isSendButtonDisabled
          }
          .animation(.spring(duration: animationDelay), value: isSendButtonHovered)
        }
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
      .glassEffect(.regular, in: .rect)
    }
  }
}

@ViewBuilder
func UserMessageView(_ message: String) -> some View {
  HStack {
    Spacer()
    Text(message)
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 6))
      .frame(maxWidth: 750, alignment: .trailing)

  }
}
