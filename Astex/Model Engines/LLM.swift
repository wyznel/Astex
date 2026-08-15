//
//  LLM.swift
//  Astex
//
//  Created by Ben Herbert on 19/07/2026.
//
import Foundation

import Ollama
import RapidMLX

class LLM {
    
    private var ollamaClient = OllamaEngine()
    private var rapidMLX = RapidMLXEngine()
    private let utilities = Utilities.shared
    
    public func generateStream(
        _ previousMessages: [Message],
        engine: ModelEngines,
        ollamaModel: String,
        rapidMLXModel: String,
        fileContext: String? = nil,
        toolRegistry: ToolRegistry? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        
        switch engine {
        case .ollama:
            return self.ollamaClient.generateStream(
                previousMessages,
                model: ollamaModel,
                fileContext: fileContext,
                toolRegistry: toolRegistry
            )
        case .rapidMLX:
            return self.rapidMLX.generateStream(
                previousMessages,
                model: rapidMLXModel,
                fileContext: fileContext,
                toolRegistry: toolRegistry
            )
        }
    }
    
    public func generateTitle(_ messages: [Message], engine: ModelEngines, ollamaModel: String) async -> String {
        switch engine {
        case .ollama :
            return await self.ollamaClient.generateTitle(messages, model: ollamaModel)
        case .rapidMLX:
            return await self.rapidMLX.generateTitle(messages)
        }
    }
    
    public func stopAllModels() async {
        do {
            try await rapidMLX.client.stopServe()
        }catch {
            print(error)
        }
        
        let _ = await utilities.tryUnloadAllModels()
        print("all models stopped.")
    }
}
