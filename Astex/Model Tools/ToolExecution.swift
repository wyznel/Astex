import Foundation

nonisolated enum ToolExecutionStatus: String, Codable, Sendable {
    case completed, denied, failed, cancelled
}

nonisolated struct ToolExecution: Codable, Sendable, Equatable {
    let name: String
    let argumentsJSON: String
    let resultJSON: String
    let status: ToolExecutionStatus

    var displayText: String {
        "\n> Tool `\(name)` \(status.rawValue).\n"
    }

    var json: String {
        // All fields use JSON string encoding, including error messages.
        String(decoding: try! JSONEncoder().encode(self), as: UTF8.self)
    }

    static func error(name: String, arguments: String, status: ToolExecutionStatus, message: String) -> Self {
        let result = String(decoding: try! JSONEncoder().encode(["error": message]), as: UTF8.self)
        return Self(name: name, argumentsJSON: arguments, resultJSON: result, status: status)
    }
}
