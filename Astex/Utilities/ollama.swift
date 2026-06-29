import Ollama
import SwiftUI
import Foundation

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
    
    // MARK: - Generate Title
    
    func generateTitle(_ previousMessages: [Message]) async -> String {
        do {
            let promptForTitleGen = Message(isUser: true, response:
                """
                Generate a short chat title based on the conversation.
                
                Rules:
                - Output only the title
                - Do not include any label such as Title or Chat Title
                - Use only letters numbers and spaces
                - No punctuation
                - Maximum 50 characters
                
                Invalid output examples:
                Chat Title: DNS Help
                "DNS Help"
                DNS Help!
                
                Example Valid output exampls:
                DNS Help
                Project Astex Debugging
                """)
            
            var something = previousMessages
            something.append(promptForTitleGen)
            
            let messageHistory = something.map { message -> Ollama.Chat.Message in
                if message.isUser {
                    return .user(message.response)
                } else {
                    return .assistant(message.response)
                }
            }
            let response = try await client.chat(
                model: "\(Settings.shared.selectedModel)",
                messages: messageHistory
            )
            return response.message.content
        } catch {
            print("Error generating chat title: \(error)")
        }
        return ""
    }
    
    //MARK: - Generate with Streaming
    
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
                        model: "\(Settings.shared.selectedModel)",
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

// MARK: -  Extend OllamaSWIFT Client to have unloadModel()

extension Ollama.Client {
    func unloadModel(model: String) -> Bool {
        
        let res = try! shell("/usr/local/bin/ollama stop \(model)")

        if res.code == 0 {
            return true
        }
        return false
    }
    
    @discardableResult
    func shell(_ command: String) throws -> (output: String, code: Int32) {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.standardInput = nil
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", command]
        task.environment = ProcessInfo.processInfo.environment

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output, task.terminationStatus)
    }
}
