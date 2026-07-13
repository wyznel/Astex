import SwiftData
import SwiftUI

@Model
final class Message {
    var isUser: Bool
    var response: String
    var chat: Chat?
    var createdAt: Date
    var isThinking: Bool = false
    var isAToolCall: Bool = false
    
    init(isUser: Bool, response: String, isThinking: Bool, isAToolCall: Bool) {
        self.isUser = isUser
        self.response = response
        self.createdAt = .now
        self.isThinking = isThinking
        self.isAToolCall = isAToolCall
    }
   
}
