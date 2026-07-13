//
//  ToolRegistry.swift
//  Astex
//
//  Created by Ben Herbert on 13/07/2026.
//
import Ollama
import Foundation

// MARK: - Tool Registry

/// Centralised registry for all LLM-callable tools.
///
/// `generateStream` interacts only with this type -- it never references
/// any specific tool or its generic Input/Output types.
///
/// All state is immutable after initialisation, making `@unchecked Sendable`
/// safe despite the existential types. To add a new tool, pass it into the
/// initialiser. No other files need to change.
final class ToolRegistry: @unchecked Sendable {
    private let tools: [String: any ExecutableTool]

    /// All registered tools as ToolProtocol instances, ready for chatStream().
    /// Cached at init to avoid allocating a new array on every access.
    let allToolProtocols: [any ToolProtocol]

    /// Whether any tools are registered.
    var isEmpty: Bool { tools.isEmpty }

    /// Initialise with an array of tools. Each tool's `name` is used as its
    /// lookup key; duplicates are resolved by last-write-wins.
    init(tools: [any ExecutableTool]) {
        var dict: [String: any ExecutableTool] = [:]
        for tool in tools {
            dict[tool.name] = tool
        }
        self.tools = dict
        self.allToolProtocols = Array(dict.values.map(\.toolProtocol))
    }

    /// Look up and execute a tool by name with the provided arguments.
    /// Returns a JSON string result suitable for appending as a `.tool()` message.
    /// Returns an error JSON string if the tool name is not registered.
    func execute(name: String, arguments: [String: Value]) async throws -> String {
        guard let tool = tools[name] else {
            return "{\"error\": \"Unknown tool: \(name)\"}"
        }
        return try await tool.execute(arguments: arguments)
    }
}
