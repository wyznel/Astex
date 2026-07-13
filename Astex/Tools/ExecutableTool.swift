//
//  ExecutableTool.swift
//  Astex
//
//  Created by Ben Herbert on 13/07/2026.
//
import Ollama
import Foundation

// MARK: - Type-Erased Tool Execution

/// Protocol that extends ollama-swift's ToolProtocol with type-erased execution.
/// Any tool conforming to this can be dispatched by name from the tool-call loop
/// without the loop needing to know the concrete Input/Output types.
protocol ExecutableTool: Sendable {
    /// The tool's registered name. Must match the name in the schema.
    var name: String { get }

    /// The underlying ToolProtocol for passing to chatStream().
    var toolProtocol: any ToolProtocol { get }

    /// Execute the tool with dynamic arguments from the model.
    /// Returns a JSON string representing the output.
    func execute(arguments: [String: Value]) async throws -> String
}

/// Generic wrapper that bridges a typed `Tool<Input, Output>` to `ExecutableTool`.
///
/// Uses JSON round-tripping to convert `[String: Value]` arguments into
/// the concrete `Input` type:
///   1. Wrap `[String: Value]` in `Value.object` and encode to JSON Data
///   2. Decode JSON Data into the concrete `Input` type
///   3. Call the tool's typed handler
///   4. Encode `Output` to a JSON String for the `.tool()` result message
///
/// This works because both `Value` and the tool `Input`/`Output` types are
/// `Codable`, sharing the same underlying JSON representation.
///
/// The encoder and decoder are cached as instance properties to avoid
/// allocating new instances on every tool invocation.
struct AnyTool<Input: Codable & Sendable, Output: Codable & Sendable>: ExecutableTool {
    let name: String
    let toolProtocol: any ToolProtocol
    private let tool: Tool<Input, Output>
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(tool: Tool<Input, Output>, name: String) {
        self.name = name
        self.tool = tool
        self.toolProtocol = tool
    }

    func execute(arguments: [String: Value]) async throws -> String {
        // Encode the [String: Value] arguments dict to JSON Data via Value's Codable conformance,
        // then decode into the concrete Input type.
        let argumentsValue = Value.object(arguments)
        let data = try encoder.encode(argumentsValue)
        let input = try decoder.decode(Input.self, from: data)

        let output = try await tool(input)

        let outputData = try encoder.encode(output)
        return String(data: outputData, encoding: .utf8) ?? "{}"
    }
}
