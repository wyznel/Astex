import Ollama
import SwiftUI
import Foundation


enum StreamChunk {
    case thinking(String)
    case content(String)
    case toolCall(String)
}

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
                
                Example Valid output examples:
                DNS Help
                Project Astex Debugging
                """, isThinking: false, isAToolCall: false)
            
            var sorted = previousMessages.sorted { $0.createdAt < $1.createdAt }
            sorted.append(promptForTitleGen)
            
            let messageHistory = sorted.map { message -> Ollama.Chat.Message in
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
    
    func generateStream(
        _ previousMessages: [Message],
        fileContext: String? = nil,
        toolRegistry: ToolRegistry? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        return AsyncThrowingStream<StreamChunk, Error> { continuation in

            let task = Task { @MainActor in
                do {
                    let sorted = previousMessages.sorted { $0.createdAt < $1.createdAt }
                    var messageHistory = sorted.map { message -> Ollama.Chat.Message in
                        if message.isUser {
                            return .user(message.response)
                        } else if !message.isThinking {
                            return .assistant(message.response)
                        } else {
                            return .assistant("")
                        }
                    }
                    messageHistory.insert(.system(
                        """
                        Do not call any tools unless necessary.
                        Do not over explain or provide irrelevant information.
                        If making a tool call, once complete, explain what you did.
                        """),
                        at: 0)
                    // Inject uploaded file contents into the last user message
                    if let fileContext {
                        if let lastIndex = messageHistory.lastIndex(where: { $0.role == .user }) {
                            let original = messageHistory[lastIndex].content
                            messageHistory[lastIndex] = .user(
                                """
                                The user has attached the following files:

                                \(fileContext)

                                User message:
                                \(original)
                                """
                            )
                        }
                    }

                    // Query model capabilities once before the loop to avoid
                    // repeated showModel HTTP requests on every iteration.
                    let capabilities = await client.modelCapabilities(
                        model: Settings.shared.selectedModel
                    )
                    let activeToolProtocols: [any ToolProtocol]? = (capabilities.supportsTools && toolRegistry != nil && !(toolRegistry!.isEmpty))
                        ? toolRegistry!.allToolProtocols : nil

                    // Tool-call loop: capped at 5 rounds to prevent runaway execution.
                    // Each iteration sends the current message history to the model.
                    // If the model responds with tool calls, the tools are executed via
                    // the registry and their results are appended before the next round.
                    var remainingRounds = 5
                    while remainingRounds > 0 {
                        remainingRounds -= 1

                        let stream = try client.chatStream(
                            model: "\(Settings.shared.selectedModel)",
                            messages: messageHistory,
                            tools: activeToolProtocols,
                            think: capabilities.supportsThinking,
                            keepAlive: .minutes(5)
                        )

                        var pendingToolCalls: [Ollama.Chat.Message.ToolCall] = []

                        for try await chunk in stream {
                            try Task.checkCancellation()

                            // Accumulate tool calls -- these arrive in the stream
                            // rather than in a single final chunk
                            if let calls = chunk.message.toolCalls, !calls.isEmpty {
                                pendingToolCalls.append(contentsOf: calls)
                            }

                            if let thinking = chunk.message.thinking, !thinking.isEmpty {
                                continuation.yield(.thinking(thinking))
                            }

                            if !chunk.message.content.isEmpty {
                                continuation.yield(.content(chunk.message.content))
                            }
                        }

                        // No tool calls in this round means the model has finished
                        if pendingToolCalls.isEmpty { break }

                        // Append the assistant's tool-call message to the history
                        messageHistory.append(
                            .assistant("", toolCalls: pendingToolCalls)
                        )

                        // Execute each tool via the registry (fully generic -- no
                        // specific tool types referenced here) and feed results back
                        for call in pendingToolCalls {
                            guard let registry = toolRegistry else { break }
                            let result = try await registry.execute(
                                name: call.function.name,
                                arguments: call.function.arguments
                            )
                            messageHistory.append(.tool(result))
                            continuation.yield(.toolCall(
                                "\n> Tool `\(call.function.name)` executed.\n"
                            ))
                        }
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

// MARK: - Extend Ollama Client with model utilities

extension Ollama.Client {

    /// Unloads a model using the ollama CLI.
    /// Uses a Process argument array instead of shell interpolation to
    /// prevent command injection via model names.
    func unloadModel(model: String) -> Bool {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama")
            process.arguments = ["stop", model]
            process.standardOutput = nil
            process.standardError = nil
            process.standardInput = nil
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Failed to unload model: \(error)")
            return false
        }
    }

    /// Queries the model once and returns both tool and thinking capabilities.
    /// Avoids making two separate showModel HTTP requests.
    func modelCapabilities(model: String) async -> ModelCapabilities {
        do {
            let modelInfo = try await self.showModel("\(model)")
            return ModelCapabilities(
                supportsTools: modelInfo.capabilities.contains(.tools),
                supportsThinking: modelInfo.capabilities.contains(.thinking)
            )
        } catch {
            print("Failed to query model capabilities: \(error)")
            return ModelCapabilities(supportsTools: false, supportsThinking: false)
        }
    }
}

/// Cached result of a single showModel query.
struct ModelCapabilities: Sendable {
    let supportsTools: Bool
    let supportsThinking: Bool
}
