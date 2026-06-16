import SwiftUI

@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var glassEffect: Glass = .regular
    @Published var colorScheme: ColorScheme = .light
    
    var holdSideBarMenuOpen: Bool = UserDefaults.standard.bool(forKey: "holdSideBarMenuOpen") {
        willSet { objectWillChange.send() }
        didSet { UserDefaults.standard.set(holdSideBarMenuOpen, forKey: "holdSideBarMenuOpen") }
    }
    
    private init() {}
}
