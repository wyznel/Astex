//
//  LLM.swift
//  Astex
//
//  Created by Ben Herbert on 19/07/2026.
//
import SwiftUI
import Foundation

import Ollama
import RapidMLX

class LLM {
    
    @ObservedObject private var settings = Settings.shared
    
    private var ollamaClient = OllamaEngine()
    private var rapidMLX = RapidMLXEngine()
    private var utilities = Utilities()
    
    public func generateStream(
        _ previousMessages: [Message],
        fileContext: String? = nil,
        toolRegistry: ToolRegistry? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        
        switch self.settings.selectedEngine {
        case .ollama:
            return self.ollamaClient.generateStream(
                previousMessages,
                fileContext: fileContext,
                toolRegistry: toolRegistry
            )
        case .rapidMLX:
            return self.rapidMLX.generateStream(
                previousMessages,
                fileContext: fileContext,
                toolRegistry: toolRegistry
            )
        }
    }
    
    public func generateTitle(_ messages: [Message]) async -> String {
        switch self.settings.selectedEngine {
        case .ollama :
            return await self.ollamaClient.generateTitle(messages)
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
