//
//  ToolRegistry.swift
//  Astex
//
//  Created by Ben Herbert on 13/07/2026.
//
import Ollama
import RapidMLX
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
    
    /// All registered tools as Ollama.ToolProtocol instances, ready for chatStream().
    /// Cached at init to avoid allocating a new array on every access.
    let allToolProtocols: [any Ollama.ToolProtocol]

    /// All registered tools adapted for RapidMLX.
    var allRapidMLXTools: [any RapidMLX.ToolProtocol] {
        return tools.values.compactMap { executableTool in
            ToolRegistry.adaptToRapidMLX(executableTool)
        }
    }

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
    func execute(name: String, arguments: [String: Ollama.Value]) async throws -> String {
        guard let tool = tools[name] else {
            return "{\"error\": \"Unknown tool: \(name)\"}"
        }
     
        let summary = "\(name): \(String(describing: arguments))"
        guard await Self.checkPermission(for: tool, summary: summary) else {
            return "{\"error\": \"Permission denied by user.\"}"
        }
     
        return try await tool.execute(arguments: arguments)
    }


    /// Look up and execute a tool by name with a raw JSON string argument.
    /// Returns a JSON string result suitable for appending as a tool result message.
    /// Returns an errsor JSON string if the tool name is not registered.
    func execute(name: String, jsonString: String) async throws -> String {
        guard let tool = tools[name] else {
            return "{\"error\": \"Unknown tool: \(name)\"}"
        }
        return try await tool.execute(jsonString: jsonString)
    }

    /// Adapts an ExecutableTool (Ollama-based) into a RapidMLX.ToolProtocol instance.
    private static func adaptToRapidMLX(_ executableTool: any ExecutableTool) -> (any RapidMLX.ToolProtocol)? {
        do {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let schemaData = try encoder.encode(executableTool.toolProtocol.schema)
            let schemaJson = try decoder.decode(RapidMLX.JSONValue.self, from: schemaData)

            guard case .object(let rootDict) = schemaJson,
                  case .object(let funcDict) = rootDict["function"] else {
                return nil
            }
            let toolName = executableTool.name
            let rapidTool = RapidMLX.Tool<[String: RapidMLX.JSONValue], RapidMLX.JSONValue>(
                schema: funcDict,
                implementation: { argumentsDict in
                    let argsData = try encoder.encode(argumentsDict)
                    let argsString = String(data: argsData, encoding: .utf8) ?? "{}"
                 
                    let summary = "\(toolName): \(argsString)"
                    guard await checkPermission(for: executableTool, summary: summary) else {
                        return .string("{\"error\": \"Permission denied by user.\"}")
                    }
                 
                    let resultString = try await executableTool.execute(jsonString: argsString)
                    let resultData = Data(resultString.utf8)
                    return (try? decoder.decode(RapidMLX.JSONValue.self, from: resultData)) ?? .string(resultString)
                }

            )
            return rapidTool
        } catch {
            print("Failed to adapt tool '\(executableTool.name)' for RapidMLX: \(error)")
            return nil
        }
    }
    
    func capability(for name: String) -> ToolCapability? {
        return tools[name]?.capability
    }
    
    private static func checkPermission(for tool: any ExecutableTool, summary: String) async -> Bool {
        guard let capability = tool.capability else {
            return true
        }
        
        return await PermissionStore.shared.requestPermission(
            tool: tool.name,
            capability: capability,
            summary: summary
        )
    }
}
