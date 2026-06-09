import Ollama
import SwiftUI

@MainActor
class LLM {
    let client = Client.default
    
    @State public var isResponseFinished: Bool = true
    
    func generateStream(
        _ previousMessages: [Message]
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            
            Task { @MainActor in
                do {
                    let messageHistory = previousMessages.map { message -> Ollama.Chat.Message in
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
