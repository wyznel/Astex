import SwiftUI
import Combine

@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var glassEffect: Glass = .regular
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Published var animationDelay: Double = 0.25
    @Published var settingsOpened: Bool = false
    
    @AppStorage("OllamaURL") var ollamaURL: String = "http://localhost:11434"
    @AppStorage("RapidMLXURL") var rapidmlxURL: String = "http://localhost:8000"
    
    
    @AppStorage("SuppressModelDeletionConfirmaton") var suppressModelDeletionConfirmation: Bool = false
    @AppStorage("ModelInformationShowSizeOnDisk") var showSizeOnDisk: Bool = true
    @AppStorage("ModelInformationShowFormat") var showFormat: Bool = true
    @AppStorage("ModelInformationShowParameterSize") var showParameterSize: Bool = true
    @AppStorage("ModelProvider") var modelProvider: ModelEngines = .ollama
    
    @AppStorage("SelectedModel") var selectedModel: String = "gemma-4-e2b-4bit"
    @AppStorage("IsFirstOpen") var isFirstOpen: Bool = true
    
    @AppStorage("IsRapidMLXInstalled") var isRapidMLXInstalled: Bool = false
    
    private init() {}
}
