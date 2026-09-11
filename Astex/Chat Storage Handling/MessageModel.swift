import SwiftData
import SwiftUI

@Model
final class Message {
    var response: String
    var chat: Chat?
    var createdAt: Date

    var type: MessageType

    init(type: MessageType, response: String) {
        self.response = response
        self.createdAt = .now
        self.type = type
    }
}
