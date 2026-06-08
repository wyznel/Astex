import SwiftData
import SwiftUI

@Model
final class Message {
  var isUser: Bool
  var response: String
  var chat: Chat?
  var createdAt: Date

  init(isUser: Bool, response: String) {
    self.isUser = isUser
    self.response = response
    self.createdAt = .now
  }

}
