//
//  MainUtilities.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//
import Ollama

class Utilities {
    
    let client = Client.default

    var AvailableModels: [String : Client.ListModelsResponse.Model] = [:]
    
/// Load necessary values.
    init() {
        Task {
            let resp = await getAvailableModels_OLLAMA()
            for model in resp {
                AvailableModels[model.name] = model
            }
        }
    }

    func getAvailableModels_OLLAMA() async -> [Client.ListModelsResponse.Model] {
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

    struct allModelInfo {
        
    }

}
