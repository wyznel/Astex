import Ollama

@MainActor
class LLM {
  let client = Client.default

  func generateStream(
    _ previousMessages: [Message]
  ) -> AsyncThrowingStream<String, Error> {
    return AsyncThrowingStream { continuation in

      Task { @MainActor in
        do {
          let messageHistory = previousMessages.map { message -> Chat.Message in
            if message.isUser {
              return .user(message.response)
            } else {
              return .assistant(message.response)
            }
          }

          for message in messageHistory {
            print("\(message.role): \(message.content)\n")
          }
          print("\n\nEND OF HISTORY\n\n")
          let stream = try client.chatStream(
            model: "llama3.2",
            messages: messageHistory,
            keepAlive: .minutes(5)
          )

          for try await chunk in stream {
            continuation.yield(chunk.message.content)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
}
