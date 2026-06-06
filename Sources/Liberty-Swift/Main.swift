import SwiftUI

struct MainWindow: View {
  @State private var prompt: String = ""
  @State private var chatWindowEmpty: Bool = true
  @State private var isSendButtonHovered: Bool = false

  @State private var isSendButtonDisabled: Bool = true

  @State private var messageList: [Message] = []
  @State private var streamingChunks: [String] = []
  private let chunkCharLimit = 500

  private var scaleFactor = 1.2
  private var animationDelay = 0.25

  private let llm = LLM()

  var body: some View {
    VStack(spacing: 12) {
      if !chatWindowEmpty {
        Spacer()
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(messageList) { message in
              if message.isUser {
                UserMessageView(message.response)
              } else {
                llmMessageView(message.response)
              }
            }
            // Streaming in-progress chunks
            ForEach(streamingChunks.indices, id: \.self) { i in
              llmMessageView(streamingChunks[i])
            }
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
              Task { @MainActor in
                await handlePromptSending()
              }
              return .handled
            }
          Button {
            Task { @MainActor in
              await handlePromptSending()
            }
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
      .selectionDisabled()
      .padding()
      .glassEffect(.regular, in: .rect)
    }
  }

  func handlePromptSending() async {
    let currentPrompt = prompt
    prompt.removeAll()
    chatWindowEmpty = false

    messageList.append(Message(isUser: true, response: currentPrompt))

    // Start with one empty chunk
    streamingChunks = [""]

    do {
      let stream = llm.generateStream(currentPrompt)

      for try await chunk in stream {
        streamingChunks[streamingChunks.count - 1] += chunk
        // If the current chunk has grown too large, start a new one
        if streamingChunks.last!.count >= chunkCharLimit {
          streamingChunks.append("")
        }
      }
    } catch {
      streamingChunks[streamingChunks.count - 1] = "LLM failed to respond."
    }

    // Collapse all chunks into a single completed Message
    let fullResponse = streamingChunks.joined()
    messageList.append(Message(isUser: false, response: fullResponse))
    streamingChunks = []
  }

}

struct Message: Identifiable {
  let id = UUID()
  let isUser: Bool
  var response: String
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

@ViewBuilder
func llmMessageView(_ message: String) -> some View {
  HStack {
    Text(message)
      .textSelection(.enabled)
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 6))
      .frame(maxWidth: 750, alignment: .leading)
    Spacer()
  }
}
