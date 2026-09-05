import RapidMLX
import SwiftUI
import Textual

struct RapidMLXModelTable: View {
    @ObservedObject private var settings = Settings.shared
    @Binding private var showsPullCard: Bool
    @Binding private var models: [RapidMLXClient.RapidModel]
    @State private var selectedModel = Settings.shared.rapidMLXSelectedModel

    let refreshModels: @MainActor @Sendable (Bool) async -> Void

    init(
        showsPullCard: Binding<Bool>,
        models: Binding<[RapidMLXClient.RapidModel]>,
        refreshModels: @escaping @MainActor @Sendable (Bool) async -> Void
    ) {
        _showsPullCard = showsPullCard
        _models = models
        self.refreshModels = refreshModels
    }

    var body: some View {
        VStack {
            header
            modelGrid
        }
        .task {
            await refreshModels(false)
        }
        .onChange(of: selectedModel) {
            settings.rapidMLXSelectedModel = selectedModel
        }
        .onChange(of: settings.rapidMLXSelectedModel) {
            selectedModel = settings.rapidMLXSelectedModel
        }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack {
            InlineText(markdown: "**RapidMLX Models**")
                .padding(6)
            Spacer()

            PullModelButton(
                showsPullCard: $showsPullCard,
                tooltipText: "Pull Model from RapidMLX"
            )

            Refresh {
                Task { await refreshModels(true) }
            }
        }
        .frame(maxWidth: 600)
    }

    private var modelGrid: some View {
        VStack(alignment: .leading) {
            Grid(
                alignment: .leading,
                horizontalSpacing: 12,
                verticalSpacing: 0
            ) {
                GridRow {
                    Text("Model Name").gridColumnAlignment(.leading)
                    Text("HF Repo").gridColumnAlignment(.leading)
                    Text("Size").gridColumnAlignment(.leading)
                    Text("Modified").gridColumnAlignment(.leading)
                    Image(systemName: "trash").opacity(0)
                }
                .padding(.vertical, 4)

                Divider()

                ForEach(models, id: \.id) { model in
                    RapidMLXModelRow(
                        model: model,
                        selectedModel: $selectedModel
                    ) {
                        withAni {
                            models.removeAll {
                                $0.alias == model.alias && $0.hfRepo == model.hfRepo
                            }
                        }
                    }
                    Divider()
                }
            }
            .padding(.leading, 12)
        }
        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
        .frame(maxWidth: 600)
        .glassEffect(settings.glassEffect, in: .rect(cornerRadius: 12))
    }
}

private struct RapidMLXModelRow: View {
    let model: RapidMLXClient.RapidModel
    @Binding var selectedModel: String
    let onDeleted: () -> Void

    private var displayName: String {
        model.alias.isEmpty ? model.hfRepo : model.alias
    }

    var body: some View {
        GridRow {
            ModelSelectionToggle(
                modelName: displayName,
                selectedModel: $selectedModel
            )
            Text(model.hfRepo)
            Text(model.size)
            Text(model.modified)

            ModelDeleteButton(
                modelName: displayName,
                isDisabled: selectedModel == displayName,
                deleteModel: deleteModel,
                onDeleted: onDeleted
            )
            
            UnloadModelButton(
                modelName: displayName,
                modelIdentifiers: [model.alias, model.hfRepo],
                engine: .rapidMLX,
                selectedModel: $selectedModel
            )
        }
        .padding(.vertical, 2)
        .background(
            Color.sepiaAccent.opacity(selectedModel == displayName ? 0.1 : 0),
            in: RoundedRectangle(cornerRadius: 6)
        )
    }

    private func deleteModel() async throws -> Bool {
        let hasAlias = !model.alias.isEmpty && model.alias != "(unmapped)"
        return try await Utilities.shared.rapidmlx_client.delete(
            alias: hasAlias ? model.alias : nil,
            hfRepo: hasAlias ? nil : model.hfRepo
        )
    }
}

struct RapidMLXModelInputCard: View {
    @Binding private var showsPullCard: Bool
    let onDone: () async -> Void

    @State private var modelName = ""
    @State private var pulledModelName = ""
    @State private var errorMessage: String?
    @State private var isPulling = false
    @State private var isComplete = false
    @State private var appeared = false

    init(
        showsPullCard: Binding<Bool>,
        onDone: @escaping () async -> Void
    ) {
        _showsPullCard = showsPullCard
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            PullCardHeader(
                title: "Pull RapidMLX Model",
                subtitle: "Download a model using RapidMLX",
                showsPullCard: $showsPullCard
            )

            HStack(spacing: 8) {
                TextField("For example: gemma-4-e2b-4bit", text: $modelName)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect(Settings.shared.glassEffect, in: .capsule)
                    .disabled(isPulling)

                Button {
                    Task { await pullModel() }
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            modelName.isEmpty
                                ? Color.sepiaText.opacity(0.2)
                                : Color.sepiaAccent
                        )
                }
                .buttonStyle(.plain)
                .disabled(modelName.isEmpty || isPulling)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if isPulling {
                VStack(spacing: 6) {
                    ProgressView()
                        .tint(Color.sepiaAccent)
                    Text("Downloading model: \(pulledModelName)...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.sepiaText.opacity(0.7))
                        .lineLimit(1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if isComplete {
                VStack(spacing: 8) {
                    Text("Finished downloading model: \(pulledModelName)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sepiaText)
                    Button("Done") {
                        showsPullCard = false
                        Task { await onDone() }
                    }
                }
            }
        }
        .pullCardStyle(appeared: appeared)
        .onAppear { withAni { appeared = true } }
        .onKeyPress(keys: [.escape], phases: .down) { _ in
            showsPullCard = false
            return .handled
        }
    }

    @MainActor
    private func pullModel() async {
        pulledModelName = modelName
        errorMessage = nil
        isComplete = false
        isPulling = true

        do {
            try await Utilities.shared.rapidmlx_client.pull(
                alias: pulledModelName,
                hfRepo: nil
            )
            isComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isPulling = false
    }
}
