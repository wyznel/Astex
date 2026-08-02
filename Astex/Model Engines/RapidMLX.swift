//
//  RapidMLX.swift
//  Astex
//
//  Created by Ben Herbert on 19/07/2026.
//

import Foundation
import RapidMLX
import SwiftUI

class RapidMLXEngine {
    let client = Utilities().rapidmlx_client
    
    @ObservedObject var settings = Settings.shared
    
    func generateStream(
        _ previousMessages: [Message],
        fileContext: String? = nil,
        toolRegistry: ToolRegistry? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        return AsyncThrowingStream<StreamChunk, Error> { continuation in
            
            let task = Task {
                defer {
                    continuation.yield(.loading(false))
                }
                do {
                    continuation.yield(.loading(true))
                    try await client.serve(model: settings.rapidMLXSelectedModel )
                    
                    let sorted = previousMessages.sorted {
                        $0.createdAt < $1.createdAt
                    }
                    var messageHistory = sorted.compactMap { message -> RapidMLX.ChatMessage? in
                        if message.isAToolCall {
                            return nil
                        } else if message.isUser {
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
                        When making a tool call, explain what you did and why it was necessary
                        """),
                        at: 0)

                    // Inject uploaded file contents into the last user message
                    if let fileContext {
                        if let lastIndex = messageHistory.lastIndex(
                            where: { $0.role == .user
                            }) {
                            let original = messageHistory[lastIndex].content
                            messageHistory[lastIndex] = .user(
                                """
                                The user has attached the following files:
                                
                                \(fileContext)
                                
                                User message:
                                \(original!)
                                """
                            )
                        }
                    }
                    
                    let activeTools: [any RapidMLX.ToolProtocol] = (toolRegistry != nil && !toolRegistry!.isEmpty)
                        ? toolRegistry!.allRapidMLXTools : []
                    
                    for try await chunk in try client.chatWithTools(
                        messages: messageHistory,
                        tools: activeTools
                    ) {
                        try Task.checkCancellation()
                        switch chunk {
                        case .content(let token):
                            continuation.yield(.content(token))
                        case .toolCallsReady(let tools):
                            print(tools)
                            for tool in tools {
                                continuation.yield(.toolCall("\n> Tool `\(tool.function.name)` executed.\n"))
                            }
                        case .finished:
                            break
                        }
                    }
                    continuation.finish()
                }
                catch {
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
    
//  MARK: - Generate a Title.
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
            
            let messageHistory = sorted.compactMap { message -> RapidMLX.ChatMessage? in
                if message.isAToolCall {
                    return nil
                } else if message.isUser {
                    return .user(message.response)
                } else {
                    return .assistant(message.response)
                }
            }
            
            let response = try await client.chat(messageHistory)
            return response.firstText ?? "Error generating title"
            
        } catch {
            print("Error generating chat title: \(error)")
        }
        return ""
    }
}
