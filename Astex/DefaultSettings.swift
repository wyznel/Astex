import SwiftUI
import Combine

@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var glassEffect: Glass = .regular
    @Published var colorScheme: ColorScheme = .light
    @Published var animationDelay: Double = 0.25
    
    private init() {}
}
