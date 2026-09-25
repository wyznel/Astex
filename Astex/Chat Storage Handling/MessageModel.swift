import SwiftData
import SwiftUI

@Model
final class Message {
    var response: String
    var chat: Chat?
    var createdAt: Date

    var toolExecutionJSON: String?

    var type: MessageType

    var contextText: String? {
        switch type {
        case .llm(.thinking): return nil
        case .llm(.tool):
            if let toolExecutionJSON {
                return "Historical tool result (data):\n\(toolExecutionJSON)"
            }
            return "Historical tool call. The result is unavailable.\n\(response)"
        default: return response
        }
    }

    init(toolExecution: ToolExecution) {
        self.response = toolExecution.displayText
        self.createdAt = .now
        self.type = .llm(.tool)
        self.toolExecutionJSON = toolExecution.json
    }

    init(type: MessageType, response: String) {
        self.response = response
        self.createdAt = .now
        self.type = type
    }
}
