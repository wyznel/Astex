import SwiftUI
import Combine
import ServiceManagement

@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var glassEffect: Glass = .regular
    @Published var animationDelay: Double = 0.25
    @Published var settingsOpened: Bool = false
    
    @AppStorage("OllamaURL") var ollamaURL: String = "http://localhost:11434"
    @AppStorage("RapidMLXURL") var rapidmlxURL: String = "http://localhost:8000"
    
    @AppStorage("IsRapidMLXInstalled") var isRapidMLXInstalled: Bool = false
    @AppStorage("IsOllamaInstalled") var isOllamaInstalled: Bool = false
    
    @AppStorage("TrafficLightVisible") var areTrafficLightsVisible: Bool = true 
    
    @AppStorage("SuppressModelDeletionConfirmaton") var suppressModelDeletionConfirmation: Bool = false
    @AppStorage("ModelInformationShowSizeOnDisk") var showSizeOnDisk: Bool = true
    @AppStorage("ModelInformationShowFormat") var showFormat: Bool = true
    @AppStorage("ModelInformationShowParameterSize") var showParameterSize: Bool = true
    @AppStorage("ModelProvider") var selectedEngine: ModelEngines = .ollama
    
    @AppStorage("SelectedModel") var selectedModel: String = ""
    @AppStorage("RapidMLXSelectedModel") var rapidMLXSelectedModel: String = ""
    
    @AppStorage("IsFirstOpen") var isFirstOpen: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("HideToolCallMessage") var hideToolCallMessage: Bool = false
    
    @AppStorage("DownloadFinishedNotification") var showModelDownloadCompleteNotifications = true
    
    @Published private(set) var launchAtLogin = false

    @AppStorage("backgroundBlur") var backgroundBlur: Double = 30.0
    @AppStorage("backgroundToggle") var isBackgroundImageEnabled: Bool = false
    @AppStorage("Appearance") var lightScheme: AppearanceOption = .system
    @AppStorage("Background") var background: Backgrounds = .none
    @AppStorage("ColourTheme") var colourTheme: ColourThemes = .sepia {
        didSet {
            let isThemeLockedToAppearance: AppearanceOption = ThemesManager.shared.checkThemePrefferedLightScheme(colourTheme.theme)
            if isThemeLockedToAppearance != .system {
                lightScheme = isThemeLockedToAppearance
            }
            
            objectWillChange.send()
        }
    }
    private init() {
        refreshLaunchAtLogin()
    }

    func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Could not change the launch-at-login setting: \(error.localizedDescription)")
        }

        refreshLaunchAtLogin()
    }

    func refreshLaunchAtLogin() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
