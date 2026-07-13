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
/// To add a new tool, register it here and create its implementation in Tools/.
/// No other files need to change.
final class ToolRegistry: @unchecked Sendable {
    private var tools: [String: any ExecutableTool] = [:]

    /// All registered tools as ToolProtocol instances, ready for chatStream().
    var allToolProtocols: [any ToolProtocol] {
        tools.values.map(\.toolProtocol)
    }

    /// Whether any tools are registered.
    var isEmpty: Bool { tools.isEmpty }

    /// Register a tool. Overwrites any existing registration with the same name.
    func register(_ tool: any ExecutableTool) {
        tools[tool.name] = tool
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
