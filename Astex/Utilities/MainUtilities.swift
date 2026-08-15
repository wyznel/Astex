//
//  MainUtilities.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//
import Ollama
import SwiftUI
import RapidMLX

class Utilities {
    
    static let shared = Utilities()
    
    // URLs are read directly from UserDefaults (thread-safe) rather than through
    // the @MainActor `Settings` singleton, since `Utilities.shared` may be first
    // touched from a non-main context.
    let client = Ollama.Client(
        host: URL(string: UserDefaults.standard.string(forKey: "OllamaURL") ?? "http://localhost:11434")!,
        userAgent: "Astex/1.0"
    )
    let rapidmlx_client = RapidMLXClient(
        baseURL: URL(string: UserDefaults.standard.string(forKey: "RapidMLXURL") ?? "http://localhost:8000")!
    )
    var AvailableModels: [String : Ollama.Client.ListModelsResponse.Model] = [:]
    
    /// Load necessary values.
    private init() {
        Task {
            let resp = await getAvailableModels_OLLAMA()
            for model in resp {
                AvailableModels[model.name] = model
            }
        }
    }

    func getAvailableModels_OLLAMA() async -> [Ollama.Client.ListModelsResponse.Model] {
        do {
            let response = try await client.listModels()
            return response.models
        }catch{
            print("Error when retrieving installed models: \(error)")
        }
        return []
    }


    func getAvailableModelsNAME_ONLY_OLLAMA() async -> [String] {
        let res = await getAvailableModels_OLLAMA()
        return res.map(\.name) as [String]
    }

    func getRapidMLXModels_NAME_ONLY() async -> [String] {
        do {
            let models = try await rapidmlx_client.getModels()
            return models.map(\.alias)
        }catch {
            print(error)
        }
        return []
    }
    
    func getModelInfo(model: String) async -> [String: Any] {
        let models = await getAvailableModels_OLLAMA()
        let matchingModel = models.first(where: { $0.name == model })
        //convert size from bytes to gb
        let size: Double = Double(matchingModel?.size ?? 1)
        let format: String = matchingModel?.details.format ?? "No Format"
        
        let parameter_size: String = matchingModel?.details.parameterSize ?? "0"
        
        
        return [
            "name": model,
            "size": size,
            "format": "\(format)",
            "parameter_size": parameter_size
        ]
    }

//  MARK: - Model memory management
    
    func areAnyModelsLoaded() async -> Bool {
        if await getRunningModels().isEmpty {
            return false
        }
        return true
    }
    
    func getRunningModels() async -> [String] {
        do {
            return (try await client.listRunningModels().models).map(\.name)
        }catch{
            print(error)
        }
        
        return []
    }
    
    func tryUnloadAllModels() async -> Bool {
        let loadedModels: [String] = await getRunningModels()
        print("loaded models: ", loadedModels)
        var unloadedModelCount: Int = 0
        let totalModels = loadedModels.count
            
        loadedModels.forEach { model in
            if client.unloadModel(model: model) {
                unloadedModelCount+=1
            }
        }

        if unloadedModelCount == totalModels {
            return true
        }
            
        return false
    }
}

// MARK: - Cleaner ```withAnimation```.

func withAni(doubled: Bool = false, customDuration: Double = 0 ,_ event: () -> Void) {
    withAnimation(.spring(duration: customDuration == 0 ? Settings.shared.animationDelay * (doubled ? 2 : 1) : customDuration)) {
        event()
    }
}


// MARK: - Executable helper

func findExecutablePath(named name: String) -> String? {
    var candidatePaths = [
        "/usr/local/bin/\(name)",
        "/opt/homebrew/bin/\(name)",
        "/usr/bin/\(name)",
        "\(NSHomeDirectory())/.local/bin/\(name)",
        "\(NSHomeDirectory())/.ollama/bin/\(name)"
    ]
    
    if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
        for dir in pathEnv.split(separator: ":") {
            let fullPath = "\(dir)/\(name)"
            if !candidatePaths.contains(fullPath) {
                candidatePaths.append(fullPath)
            }
        }
    }
    
    for path in candidatePaths {
        if FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
    }
    return nil
}


// MARK: - Check if Ollama / RapidMLX installed

func isOllamaInstalled() -> Bool {
    return findExecutablePath(named: "ollama") != nil
}

func isRapidMLXInstalled() -> Bool {
    return findExecutablePath(named: "rapid-mlx") != nil
}
