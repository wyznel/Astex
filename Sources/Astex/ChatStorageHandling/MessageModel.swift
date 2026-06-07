import SwiftData

@Model
final class Message {
  var isUser: Bool
  var response: String
  var chat: Chat?

  init(isUser: Bool, response: String) {
    self.isUser = isUser
    self.response = response
  }
}
