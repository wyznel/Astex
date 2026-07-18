import SwiftUI
import Combine

@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var glassEffect: Glass = .regular
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Published var animationDelay: Double = 0.25
    @Published var settingsOpened: Bool = false
    
    @AppStorage("SuppressModelDeletionConfirmaton") var suppressModelDeletionConfirmation: Bool = false
    @AppStorage("ModelInformationShowSizeOnDisk") var showSizeOnDisk: Bool = true
    @AppStorage("ModelInformationShowFormat") var showFormat: Bool = true
    @AppStorage("ModelInformationShowParameterSize") var showParameterSize: Bool = true
    @AppStorage("ModelProvider") var modelProvider: ModelEngines = .ollama
    
    @AppStorage("SelectedModel") var selectedModel: String = ""
    @AppStorage("IsFirstOpen") var isFirstOpen: Bool = true
    
    private init() {}
}
