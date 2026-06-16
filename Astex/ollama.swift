import Ollama
import SwiftUI

@MainActor
class LLM {
    let client = Client.default
    
    func getAvailableModels() async -> [Client.ListModelsResponse.Model] {
        do{
            let response = try await client.listModels()
            return response.models
        }catch{
            print("Error when retrieving installed models: \(error)")
        }
        return []
    }
    
    @State public var isResponseFinished: Bool = true
    
    func generateTitle(_ previousMessages: [Message]) async -> String {
        do {
            let messageHistory = previousMessages.map { message -> Ollama.Chat.Message in
                if message.isUser {
                    return .user(message.response)
                } else {
                    return .assistant(message.response)
                }
            }
            let response = try await client.chat(
                model: "llama3.2",
                messages: messageHistory,
                keepAlive: .minutes(-1)
            )
            return response.message.content
        } catch {
            print("Error generating chat title: \(error)")
        }
        return ""
    }
    
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
