import SwiftData
import SwiftUI

@Model
final class Chat {
  var title: String
  var createdAt: Date
  @Relationship(deleteRule: .cascade) var messages: [Message]

  init(title: String) {
    self.title = title
    self.createdAt = .now
    self.messages = []
  }

}
