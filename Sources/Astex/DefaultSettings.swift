import SwiftUI

@MainActor
class Settings: ObservableObject {
  static let shared = Settings()

  @Published var glassEffect: Glass = .regular
  @Published var colorScheme: ColorScheme = .light

  private init() {}
}
