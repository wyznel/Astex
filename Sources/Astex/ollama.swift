import Ollama
import SwiftUI

@MainActor
class LLM {
    let client = Client.default
    
    @State public var isResponseFinished: Bool = true
    
    func generateStream(_ previousMessages: [Message]) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream<String, Error> { continuation in
            
            let task = Task { @MainActor in
                do {
                    let messageHistory = previousMessages.map { message -> Ollama.Chat.Message in
                        if message.isUser {
                            return .user(message.response)
                        } else {
                            return .assistant(message.response)
                        }
                    }
                    
                    let stream = try client.chatStream(
                        model: "llama3.2",
                        messages: messageHistory,
                        keepAlive: .minutes(5)
                    )
                    
                    for try await chunk in stream {
                        try Task.checkCancellation()
                        continuation.yield(chunk.message.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    task.cancel()
                }
            }

        }
    }
}
