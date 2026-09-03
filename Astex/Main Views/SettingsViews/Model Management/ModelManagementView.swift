//
//  ModelManagementView.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import RapidMLX

// MARK: - ModelManagementView

struct ModelManagementView: View {

    // MARK: Properties

    @ObservedObject private var settings = Settings.shared
    @State private var models: [String] = []
    @State private var rapidModels: [RapidMLXClient.RapidModel] = []

    @State private var showTextInput: Bool = false
    @State private var showRapidMLXTextInput: Bool = false

    private let cache = DataCache.shared
    
    // MARK: Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    ModelProvider()
                    if settings.isOllamaInstalled {
                        OllamaModelTable(showTextInput: $showTextInput, models: $models) {
                            await refreshAvailableModels()
                        }
                    }
                    if settings.isRapidMLXInstalled {
                        RapidMLXModelTable(showPullInput: $showRapidMLXTextInput, rapidModels: $rapidModels) {
                            await refreshRapidMLXModels()
                        }
                    }
                }
                .padding(.vertical)
            }
            .blur(radius: (showTextInput || showRapidMLXTextInput) ? 5 : 0)

            if showTextInput {
                ModelInputCard(showTextInput: $showTextInput) {
                    Task {
                        await refreshAvailableModels()
                    }
                }
            }

            if showRapidMLXTextInput {
                RapidMLXModelInputCard(showTextInput: $showRapidMLXTextInput) {
                    Task {
                        await refreshRapidMLXModels()
                    }
                }
            }
        }
    }

    // MARK: - Refresh Models List

    func refreshAvailableModels() async {
        models = await Utilities.shared.getAvailableModelsNAME_ONLY_OLLAMA()
    }

    func refreshRapidMLXModels(overrideCache: Bool = false) async {
        rapidModels = await Utilities.shared.getRapidMLXModels(overrideCache: overrideCache)
    }
}
