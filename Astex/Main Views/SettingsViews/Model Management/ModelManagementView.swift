//
//  ModelManagementView.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import RapidMLX

struct ModelManagementView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var ollamaModels: [String] = []
    @State private var rapidMLXModels: [RapidMLXClient.RapidModel] = []
    @State private var showsOllamaPullCard = false
    @State private var showsRapidMLXPullCard = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    ModelProviderPicker()

                    if settings.isOllamaInstalled {
                        OllamaModelTable(
                            showsPullCard: $showsOllamaPullCard,
                            models: $ollamaModels,
                            refreshModels: refreshOllamaModels
                        )
                    }

                    if settings.isRapidMLXInstalled {
                        RapidMLXModelTable(
                            showsPullCard: $showsRapidMLXPullCard,
                            models: $rapidMLXModels,
                            refreshModels: refreshRapidMLXModels
                        )
                    }
                }
                .padding(.vertical)
            }
            .blur(radius: showsOllamaPullCard || showsRapidMLXPullCard ? 5 : 0)

            if showsOllamaPullCard {
                OllamaModelInputCard(showsPullCard: $showsOllamaPullCard) {
                    await refreshOllamaModels()
                }
            }

            if showsRapidMLXPullCard {
                RapidMLXModelInputCard(showsPullCard: $showsRapidMLXPullCard) {
                    await refreshRapidMLXModels()
                }
            }
        }
    }

    private func refreshOllamaModels() async {
        ollamaModels = await Utilities.shared.getAvailableModelsNAME_ONLY_OLLAMA()
    }

    private func refreshRapidMLXModels(_ overrideCache: Bool = false) async {
        rapidMLXModels = await Utilities.shared.getRapidMLXModels(overrideCache: overrideCache)
    }
}

private struct ModelProviderPicker: View {
    @ObservedObject private var settings = Settings.shared
    @State private var isResetIconRotated = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Select Model Engine")
                .font(.headline)

            HStack(spacing: 12) {
                Text("Engine")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Button {
                    withAni {
                        isResetIconRotated = true
                    }
                    settings.selectedEngine = .ollama
                    isResetIconRotated = false
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .foregroundStyle(Color.sepiaAccent)
                        .rotationEffect(.degrees(isResetIconRotated ? -360 : 0))
                }
                .buttonStyle(.plain)
                .tooltip(delay: 1.0, offsetX: 75) {
                    Text("Reset to default model engine (Ollama)")
                        .fixedSize()
                }

                Picker("Engine", selection: $settings.selectedEngine) {
                    ForEach(ModelEngines.allCases, id: \.self) { engine in
                        Text(engine.rawValue)
                            .tag(engine)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(
                settings.glassEffect.tint(Color.sepiaBackground.opacity(0.5)),
                in: .rect(cornerRadius: 10)
            )
            .frame(maxWidth: 600)
        }
    }
}

struct UnloadModelButton: View {
    let modelName: String
    var modelIdentifiers: Set<String> = []
    let engine: ModelEngines
    @Binding var selectedModel: String
    @State private var isLoaded = false

    var body: some View {
        Button {
            switch engine {
            case .ollama:
                if Utilities.shared.ollama_client.unloadModel(model: modelName) {
                    isLoaded = false
                }
            case .rapidMLX:
                Task {
                    do {
                        try await Utilities.shared.rapidmlx_client.stopServe()
                        isLoaded = false
                    } catch {
                        print("Could not unload the RapidMLX model: \(error)")
                    }
                }
            }
        } label: {
            Image(systemName: "stop.circle")
                .contentShape(Rectangle())
        }
        .opacity(isLoaded || selectedModel == modelName ? 1 : 0)
        .disabled(!isLoaded)
        .contentShape(Rectangle())
        .task {
            switch engine {
            case .ollama:
                let loadedModels = await Utilities.shared.getRunningOllamaModels()
                isLoaded = loadedModels.contains(modelName)

            case .rapidMLX:
                guard let runningModel = await Utilities.shared.getRunningRapidMLXModel() else {
                    isLoaded = false
                    return
                }

                isLoaded = modelIdentifiers.union([modelName]).contains(runningModel)
            }
        }
        .tooltip(alignment: .top) {
            Text("Unload Model")
        }
    }
}
