import SwiftData
import SwiftUI

@Model
final class Message {
    var response: String
    var chat: Chat?
    var createdAt: Date

    private var isUser: Bool = false
    private var isThinking: Bool = false
    private var isAToolCall: Bool = false

    @Attribute(originalName: "type")
    private var storedType: MessageType?

    var type: MessageType {
        get {
            if let storedType {
                return storedType
            }

            if isUser {
                return .user
            }

            if isThinking {
                return .llm(.thinking)
            }

            if isAToolCall {
                return .llm(.tool)
            }

            return .llm(.response)
        }
        set {
            storedType = newValue
            isUser = newValue == .user
            isThinking = newValue == .llm(.thinking)
            isAToolCall = newValue == .llm(.tool)
        }
    }

    init(type: MessageType, response: String) {
        self.response = response
        self.createdAt = .now
        self.storedType = type
        self.isUser = type == .user
        self.isThinking = type == .llm(.thinking)
        self.isAToolCall = type == .llm(.tool)
    }
}
