//
//  RapidMLXModelHandling.swift
//  Astex
//
//  Created by Ben Herbert on 15/08/2026.
//

import SwiftUI
import RapidMLX
import Textual


struct RapidMLXModelInputCard: View {

    @Binding var showTextInput: Bool

    var onDone: () -> Void

    @State private var input_field = ""
    @State private var modelName = ""

    @State private var errorMessage: String?
    @State private var downloadInProgress: Bool = false
    @State private var isSuccess: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Header area with icon and close button
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.sepiaAccent)

                    Text("Pull RapidMLX Model")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.sepiaText)

                    Text("Download a model using RapidMLX")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.sepiaText.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

                Button {
                    withAni {
                        showTextInput = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.sepiaText.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .glassEffect(Settings.shared.glassEffect, in: .circle)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("e.g. gemma-4-e2b-4bit", text: $input_field)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect(Settings.shared.glassEffect, in: .capsule)
                    .disabled(downloadInProgress)

                Button {
                    modelName = input_field
                    errorMessage = nil
                    withAni {
                        downloadInProgress = true
                    }
                    Task {
                        do {
                            try await Utilities.shared.rapidmlx_client.pull(
                                alias: modelName,
                                hfRepo: nil
                            )
                            withAni {
                                isSuccess = true
                                downloadInProgress = false
                            }
                        } catch {
                            withAni {
                                errorMessage = error.localizedDescription
                                downloadInProgress = false
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            input_field.isEmpty
                                ? Color.sepiaText.opacity(0.2)
                                : Color.sepiaAccent
                        )
                }
                .buttonStyle(.plain)
                .disabled(input_field.isEmpty || downloadInProgress)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            // Download progress
            if downloadInProgress && !isSuccess {
                VStack(spacing: 6) {
                    ProgressView()
                        .tint(Color.sepiaAccent)

                    Text("Downloading model: \(modelName)...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.sepiaText.opacity(0.7))
                        .lineLimit(1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if isSuccess {
                VStack(spacing: 8) {
                    Text("Finished downloading model: \(modelName)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sepiaText)

                    Button {
                        withAni {
                            showTextInput = false
                        }
                        onDone()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .glassEffect(Settings.shared.glassEffect, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .offset(y: -100)
        .onAppear {
            withAni {
                appeared = true
            }
        }
        .onKeyPress(keys: [.escape], phases: .down) { keyPress in
            withAni {
                showTextInput = false
            }
            return .handled
        }
    }
}


struct RapidMLXModelRow: View {
    let model: RapidMLXClient.RapidModel
    @Binding var selectedModel: String?
    var onDeleted: () -> Void

    private var displayName: String { model.alias.isEmpty ? model.hfRepo : model.alias }

    @ViewBuilder
    var body: some View {
        GridRow {
            ModelToggle(
                modelName: displayName,
                selectedModel: $selectedModel
            )
            Text(model.hfRepo)
            Text(model.size)
            Text(model.modified)

            ModelDeleteButton(
                modelName: displayName,
                isDisabled: selectedModel == displayName,
                onDeleteAsync: {
                    let aliasParam = model.alias.isEmpty ? nil : model.alias
                    let repoParam = model.alias.isEmpty ? model.hfRepo : nil
                    return try await Utilities.shared.rapidmlx_client.delete(alias: aliasParam, hfRepo: repoParam)
                },
                onDelete: {
                    onDeleted()
                }
            )
        }
        .padding(.vertical, 2)
        .background(
            Color.sepiaAccent.opacity(selectedModel == displayName ? 0.1 : 0.0),
            in: RoundedRectangle(cornerRadius: 6)
        )
        Divider()
    }
}



struct RapidMLXModelTable: View {
    @ObservedObject private var settings = Settings.shared
    @Binding var showPullInput: Bool
    @Binding var rapidModels: [RapidMLXClient.RapidModel]
    var refreshRapidMLXModels: () async -> Void

    @State private var selectedModel: String? = Settings.shared.rapidMLXSelectedModel

    var body: some View {
        VStack {
            HStack {
                InlineText(markdown: "**RapidMLX Models**")
                    .padding(6)
                    .frame(alignment: .leading)
                Spacer()

                PullModelButton(showTextInput: $showPullInput, tooltipText: "Pull Model from RapidMLX")

                Refresh {
                    Task {
                        await refreshRapidMLXModels()
                    }
                }
            }
            .frame(maxWidth: 600)

            VStack(alignment: .leading) {
                Grid(
                    alignment: .leading,
                    horizontalSpacing: 12,
                    verticalSpacing: 0
                ) {
                    // Header row
                    GridRow {
                        Text("Model Name")
                            .gridColumnAlignment(.leading)
                        Text("HF Repo")
                            .gridColumnAlignment(.leading)
                        Text("Size")
                            .gridColumnAlignment(.leading)
                        Text("Modified")
                            .gridColumnAlignment(.leading)

                        // Invisible trash icon to reserve the action column width
                        Image(systemName: "trash")
                            .opacity(0)
                    }
                    .padding(.vertical, 4)

                    Divider()

                    // Data rows
                    ForEach(rapidModels, id: \.alias) { model in
                        RapidMLXModelRow(
                            model: model,
                            selectedModel: $selectedModel,
                            onDeleted: {
                                withAni {
                                    rapidModels.removeAll { $0.alias == model.alias && $0.hfRepo == model.hfRepo }
                                }
                            }
                        )
                    }
                }
                .padding(.leading, 12)
            }
            .padding(.top, 15)
            .padding(.bottom, 15)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .frame(maxWidth: 600)
            .glassEffect(
                settings.glassEffect,
                in: .rect(cornerRadius: 12)
            )
            .onChange(of: selectedModel) {
                Settings.shared.rapidMLXSelectedModel = selectedModel ?? ""
                print("Selected RapidMLX Model: \(Settings.shared.rapidMLXSelectedModel)")
            }
            .onChange(of: settings.rapidMLXSelectedModel) {
                selectedModel = settings.rapidMLXSelectedModel
            }
        }
        .task {
            await refreshRapidMLXModels()
        }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
