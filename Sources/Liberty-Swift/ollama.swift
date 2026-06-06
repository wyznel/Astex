import Ollama

@MainActor
class LLM {
  let client = Client.default

  func generateStream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
    let stream = client.generateStream(
      model: "llama3.2",
      prompt: prompt,
      options: [
        "temperature": 0.7,
        "max_tokens": 100,
      ],
      keepAlive: .minutes(5)
    )

    return AsyncThrowingStream { continuation in
      Task { @MainActor in
        do {
          for try await chunk in stream {
            continuation.yield(chunk.response)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
}
