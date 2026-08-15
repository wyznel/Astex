//
//  UnloadModels.swift
//  Astex
//
//  Created by Ben Herbert on 15/08/2026.
//

import Ollama
import SwiftUI

struct UnloadAllModelsButton: View {

    enum ButtonText {
        case success
        case unload
        case none

        var text: String {
            switch self {
            case .success:
                return "Successfully Unloaded All Models"
            case .unload:
                return "Unload All Models"
            case .none:
                return "No Models Loaded"
            }
        }
    }

    @State private var success: Bool = false
    @State private var isEnabled: Bool = false

    @State private var areAnyModelsLoaded: Bool = false

    @State private var selectedText: ButtonText = .unload

    var body: some View {
        Button {
            Task {
                if await Utilities.shared.tryUnloadAllModels() {
                    success = true
                    areAnyModelsLoaded = false

                    setIndex(to: .success)

                    try? await Task.sleep(for: .seconds(5))
                    success = false
                    setIndex(to: .none)

                } else {
                    success = false
                }
            }
        } label: {
            Label(selectedText.text, systemImage: "trash")
        }
        .disabled(!areAnyModelsLoaded)
        .task {
            areAnyModelsLoaded = await Utilities.shared.areAnyModelsLoaded()
            if areAnyModelsLoaded {
                setIndex(to: .unload)
            }else{
                setIndex(to: .none)
            }
        }
    }

    private func setIndex(to newIndex: ButtonText) {
        withAni {
            selectedText = newIndex
        }
    }

}



struct UnloadThisModel: View {
    let modelName: String
    let isDisabled: Bool

    @Binding var selectedModel: String?

    @State var isLoaded: Bool = false

    var body: some View {
        Button {
            if Utilities.shared.client.unloadModel(model: modelName) {
                isLoaded = false
            }
        } label: {
            Image(systemName: "stop.circle")
                .contentShape(Rectangle())
        }
        .opacity((isLoaded || selectedModel == modelName) ? 1 : 0)
        .disabled(selectedModel == modelName && !isLoaded)
        .contentShape(Rectangle())
        .task {
            if await Utilities.shared.areAnyModelsLoaded() {
                let loadedModels = await Utilities.shared.getRunningModels()

                loadedModels.forEach { model in
                    if modelName == model {
                        isLoaded = true
                    }
                }
            }
        }
        .tooltip(alignment: .top){
            Text("Unload Model")
        }
    }
}
