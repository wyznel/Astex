import Ollama
import RapidMLX
import Foundation

/// All dispatch paths use the same permission check and result format.
final class ToolRegistry: Sendable {
    private let tools: [String: any ExecutableTool]
    private let permissionStore: PermissionStore
    let allToolProtocols: [any Ollama.ToolProtocol]

    var allRapidMLXTools: [any RapidMLX.ToolProtocol] {
        tools.values.compactMap { adaptToRapidMLX($0) }
    }

    var isEmpty: Bool { tools.isEmpty }

    init(tools: [any ExecutableTool], permissionStore: PermissionStore = .shared) {
        let dict = Dictionary(tools.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last })
        self.tools = dict
        self.permissionStore = permissionStore
        self.allToolProtocols = Array(dict.values.map(\.toolProtocol))
    }

    func execute(name: String, arguments: [String: Ollama.Value]) async -> ToolExecution {
        do {
            let data = try JSONEncoder().encode(Ollama.Value.object(arguments))
            return await execute(name: name, jsonString: String(decoding: data, as: UTF8.self))
        } catch {
            return .error(name: name, arguments: "{}", status: .failed, message: error.localizedDescription)
        }
    }

    func execute(name: String, jsonString: String) async -> ToolExecution {
        guard !Task.isCancelled else {
            return .error(name: name, arguments: jsonString, status: .cancelled, message: "The tool call was cancelled.")
        }
        guard let tool = tools[name] else {
            return .error(name: name, arguments: jsonString, status: .failed, message: "Unknown tool: \(name)")
        }
        if let capability = tool.capability {
            let allowed = await permissionStore.requestPermission(
                tool: name, capability: capability, summary: "\(name): \(jsonString)"
            )
            guard allowed else {
                return .error(name: name, arguments: jsonString,
                              status: Task.isCancelled ? .cancelled : .denied,
                              message: "Permission denied.")
            }
        }
        do {
            try Task.checkCancellation()
            let result = try await tool.execute(jsonString: jsonString)
            let value = try JSONDecoder().decode(Ollama.Value.self, from: Data(result.utf8))
            var status = ToolExecutionStatus.completed
            if case .object(let fields) = value,
               fields["success"] == .bool(false) || fields["error"] != nil {
                status = .failed
            }
            return ToolExecution(name: name, argumentsJSON: jsonString, resultJSON: result, status: status)
        } catch {
            return .error(name: name, arguments: jsonString,
                          status: error is CancellationError ? .cancelled : .failed,
                          message: error.localizedDescription)
        }
    }

    private func adaptToRapidMLX(_ tool: any ExecutableTool) -> (any RapidMLX.ToolProtocol)? {
        do {
            let data = try JSONEncoder().encode(tool.toolProtocol.schema)
            let schema = try JSONDecoder().decode(RapidMLX.JSONValue.self, from: data)
            guard case .object(let root) = schema,
                  case .object(let function) = root["function"] else { return nil }
            return RapidMLX.Tool<[String: RapidMLX.JSONValue], RapidMLX.JSONValue>(schema: function) { arguments in
                let data = try JSONEncoder().encode(arguments)
                let result = await self.execute(name: tool.name, jsonString: String(decoding: data, as: UTF8.self))
                return try JSONDecoder().decode(RapidMLX.JSONValue.self, from: Data(result.json.utf8))
            }
        } catch {
            print("Failed to adapt tool '\(tool.name)': \(error)")
            return nil
        }
    }

    func capability(for name: String) -> ToolCapability? {
        tools[name]?.capability
    }
}
