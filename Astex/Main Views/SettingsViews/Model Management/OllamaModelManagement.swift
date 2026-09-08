import Observation
import Ollama
import SwiftUI
import Textual

struct OllamaModelTable: View {
    private static let columns: [OllamaModelColumn] = [
        .init(
            id: "sizeOnDisk",
            title: "Size on Disk",
            keyPath: \.sizeOnDisk,
            isVisible: { $0.showSizeOnDisk }
        ),
        .init(
            id: "format",
            title: "Format",
            keyPath: \.format,
            isVisible: { $0.showFormat }
        ),
        .init(
            id: "parameterSize",
            title: "Parameter Size",
            keyPath: \.parameterSize,
            isVisible: { $0.showParameterSize }
        )
    ]

    @ObservedObject private var settings = Settings.shared
    @Binding private var showsPullCard: Bool
    @Binding private var models: [String]
    @State private var selectedModel = Settings.shared.selectedModel

    let refreshModels: () async -> Void

    init(
        showsPullCard: Binding<Bool>,
        models: Binding<[String]>,
        refreshModels: @escaping () async -> Void
    ) {
        _showsPullCard = showsPullCard
        _models = models
        self.refreshModels = refreshModels
    }

    private var visibleColumns: [OllamaModelColumn] {
        Self.columns.filter { $0.isVisible(settings) }
    }

    var body: some View {
        VStack {
            header
            modelGrid
        }
        .task {
            await refreshModels()
            selectFirstModelIfNeeded()
        }
        .onChange(of: selectedModel) {
            settings.selectedModel = selectedModel
        }
        .onChange(of: settings.selectedModel) {
            selectedModel = settings.selectedModel
        }
        .contextMenu { columnMenu }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack {
            InlineText(markdown: "**Ollama Models**")
                .padding(6)
            Spacer()

            PullModelButton(
                showsPullCard: $showsPullCard,
                tooltipText: "Pull Model from Ollama"
            )

            Refresh {
                Task { await refreshModels() }
            }
            UnloadAllModelsButton()
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
                    Text("Model Name")
                        .gridColumnAlignment(.leading)

                    ForEach(visibleColumns) { column in
                        Text(column.title)
                            .gridColumnAlignment(.leading)
                    }

                    Image(systemName: "trash")
                        .opacity(0)
                    Image(systemName: "stop.circle")
                        .opacity(0)
                }
                .padding(.vertical, 4)

                Divider()

                ForEach(models, id: \.self) { model in
                    OllamaModelRow(
                        modelName: model,
                        selectedModel: $selectedModel,
                        visibleColumns: visibleColumns
                    ) {
                        withAni {
                            models.removeAll { $0 == model }
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

    @ViewBuilder
    private var columnMenu: some View {
        Toggle("Size on Disk", isOn: $settings.showSizeOnDisk)
        Toggle("Format", isOn: $settings.showFormat)
        Toggle("Parameter Size", isOn: $settings.showParameterSize)
    }

    private func selectFirstModelIfNeeded() {
        if settings.selectedModel.isEmpty, let firstModel = models.first {
            settings.selectedModel = firstModel
        }
    }
}

private struct OllamaModelColumn: Identifiable {
    let id: String
    let title: String
    let keyPath: KeyPath<OllamaModelRowData, String>
    let isVisible: (Settings) -> Bool
}

private struct OllamaModelRow: View {
    let modelName: String
    @Binding var selectedModel: String
    let visibleColumns: [OllamaModelColumn]
    let onDeleted: () -> Void

    @State private var data: OllamaModelRowData

    init(
        modelName: String,
        selectedModel: Binding<String>,
        visibleColumns: [OllamaModelColumn],
        onDeleted: @escaping () -> Void
    ) {
        self.modelName = modelName
        _selectedModel = selectedModel
        self.visibleColumns = visibleColumns
        self.onDeleted = onDeleted
        _data = State(initialValue: OllamaModelRowData(modelName: modelName))
    }

    var body: some View {
        GridRow {
            ModelSelectionToggle(
                modelName: modelName,
                selectedModel: $selectedModel
            )

            if data.isLoading {
                ProgressView()
                    .gridCellColumns(visibleColumns.count + 2)
            } else {
                ForEach(visibleColumns) { column in
                    Text(data[keyPath: column.keyPath])
                }

                ModelDeleteButton(
                    modelName: modelName,
                    isDisabled: selectedModel == modelName,
                    deleteModel: deleteModel,
                    onDeleted: onDeleted
                )

                UnloadModelButton(
                    modelName: modelName,
                    engine: .ollama,
                    selectedModel: $selectedModel
                )
            }
        }
        .padding(.vertical, 2)
        .background(
            ThemesManager.shared.getAccentColour().opacity(selectedModel == modelName ? 0.1 : 0),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .task(id: modelName) {
            await data.load()
        }
    }

    private func deleteModel() async throws -> Bool {
        guard let modelID = Ollama.Model.ID(rawValue: modelName) else {
            return false
        }

        return try await Utilities.shared.ollama_client.deleteModel(modelID)
    }
}

@MainActor
@Observable
private final class OllamaModelRowData {
    let modelName: String
    private(set) var sizeOnDisk = "--"
    private(set) var format = "--"
    private(set) var parameterSize = "--"
    private(set) var isLoading = true

    init(modelName: String) {
        self.modelName = modelName
    }

    func load() async {
        let info = await Utilities.shared.getModelInfo(model: modelName)
        let rawSize = info["size"] as? Double ?? 0
        let sizeInGigabytes = (rawSize / 1_000_000_000 * 100).rounded() / 100

        sizeOnDisk = "\(sizeInGigabytes) GB"
        format = info["format"] as? String ?? "Unknown"
        parameterSize = info["parameter_size"] as? String ?? "0"
        isLoading = false
    }
}

struct OllamaModelInputCard: View {
    @Binding private var showsPullCard: Bool
    let onDone: () async -> Void

    @State private var modelName = ""
    @State private var pulledModelName = ""
    @State private var progressText = ""
    @State private var errorMessage: String?
    @State private var isPulling = false
    @State private var isComplete = false
    @State private var progress = 0.0
    @State private var appeared = false

    @ObservedObject var settings = Settings.shared
    
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
                title: "Pull Model",
                subtitle: "Download a model from the Ollama library",
                showsPullCard: $showsPullCard
            )

            HStack(spacing: 8) {
                TextField("For example: llama3.2:3b", text: $modelName)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect(settings.glassEffect, in: .capsule)
                    .disabled(isPulling)

                Button {
                    Task { await pullModel() }
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            modelName.isEmpty
                            ? ThemesManager.shared.getTextColour().opacity(0.2)
                            : ThemesManager.shared.getAccentColour()
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
                PullProgressView(progress: progress, status: progressText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if isComplete {
                Text("Finished downloading model: \(pulledModelName)")
                Button("Done") {
                    showsPullCard = false
                    Task { await onDone() }
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
        progress = 0
        progressText = ""
        errorMessage = nil
        isComplete = false
        isPulling = true

        guard let modelID = Ollama.Model.ID(rawValue: pulledModelName) else {
            errorMessage = "Enter a valid model name."
            isPulling = false
            return
        }

        do {
            for try await update in Utilities.shared.ollama_client.pullModelStream(modelID) {
                progressText = update.status
                if let total = update.total, let completed = update.completed, total > 0 {
                    progress = Double(completed) / Double(total) * 100
                }
            }
            isComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isPulling = false
    }
}

private struct PullProgressView: View {
    let progress: Double
    let status: String

    var body: some View {
        VStack(spacing: 6) {
            ProgressView(value: progress, total: 100)
                .tint(ThemesManager.shared.getAccentColour())

            HStack {
                Text(status)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ThemesManager.shared.getTextColour().opacity(0.7))
                    .lineLimit(1)
                Spacer()
                Text("\(Int(progress))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ThemesManager.shared.getAccentColour())
            }
        }
    }
}

struct PullCardHeader: View {
    let title: String
    let subtitle: String
    @Binding var showsPullCard: Bool
    
    @ObservedObject var settings = Settings.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(ThemesManager.shared.getAccentColour())
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ThemesManager.shared.getTextColour())
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(ThemesManager.shared.getTextColour().opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            Button {
                showsPullCard = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ThemesManager.shared.getTextColour().opacity(0.4))
                    .frame(width: 22, height: 22)
                    .glassEffect(settings.glassEffect, in: .circle)
            }
            .buttonStyle(.plain)
        }
    }
}

extension View {
    
    func pullCardStyle(appeared: Bool) -> some View {
        @ObservedObject var settings = Settings.shared
        
        return padding(20)
                .frame(width: 320)
                .glassEffect(settings.glassEffect, in: .rect(cornerRadius: 18))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .offset(y: -100)
    }
}

struct PullModelButton: View {
    @Binding var showsPullCard: Bool
    let tooltipText: String

    var body: some View {
        Button {
            showsPullCard = true
        } label: {
            Image(systemName: "plus")
        }
        .settingsIconButtonStyle()
        .tooltip(delay: 1.0, offsetX: 40) {
            Text(tooltipText)
        }
    }
}

struct ModelSelectionToggle: View {
    let modelName: String
    @Binding var selectedModel: String

    var body: some View {
        Toggle(
            modelName,
            isOn: Binding(
                get: { selectedModel == modelName },
                set: { isSelected in
                    selectedModel = isSelected ? modelName : ""
                }
            )
        )
        .disabled(selectedModel == modelName)
    }
}

struct ModelDeleteButton: View {
    let modelName: String
    let isDisabled: Bool
    let deleteModel: () async throws -> Bool
    let onDeleted: () -> Void

    @ObservedObject private var settings = Settings.shared
    @State private var deletionSucceeded = false
    @State private var showsDeletionResult = false
    @State private var showsDeletionConfirmation = false

    var body: some View {
        Button {
            if settings.suppressModelDeletionConfirmation {
                Task { await delete() }
            } else {
                showsDeletionConfirmation = true
            }
        } label: {
            Image(systemName: "trash")
        }
        .settingsIconButtonStyle(role: .destructive)
        .tooltip {
            Text("Delete Model")
                .fixedSize()
        }
        .disabled(isDisabled)
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showsDeletionConfirmation
        ) {
            Button("Delete model: \(modelName)", role: .destructive) {
                Task { await delete() }
            }
        }
        .dialogIcon(Image(systemName: "trash.circle.fill"))
        .dialogSuppressionToggle(
            isSuppressed: settings.$suppressModelDeletionConfirmation
        )
        .alert(isPresented: $showsDeletionResult) {
            Alert(
                title: Text(
                    deletionSucceeded
                        ? "Successfully deleted model: \(modelName)"
                        : "Failed to delete model!"
                ),
                message: Text(
                    deletionSucceeded
                        ? "Removed model: \(modelName)"
                        : "Unable to remove model: \(modelName)"
                ),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @MainActor
    private func delete() async {
        do {
            deletionSucceeded = try await deleteModel()
            if deletionSucceeded {
                onDeleted()
            }
        } catch {
            deletionSucceeded = false
        }
        showsDeletionResult = true
    }
}

private struct UnloadAllModelsButton: View {
    @State private var label = LabelState.unload
    @State private var hasLoadedModels = false

    var body: some View {
        Button {
            Task { await unloadAllModels() }
        } label: {
            Label(label.text, systemImage: "trash")
        }
        .settingsButtonStyle()
        .disabled(!hasLoadedModels)
        .task {
            hasLoadedModels = await Utilities.shared.areAnyModelsLoaded()
            label = hasLoadedModels ? .unload : .none
        }
    }

    private func unloadAllModels() async {
        guard await Utilities.shared.tryUnloadAllModels() else { return }

        hasLoadedModels = false
        label = .success
        try? await Task.sleep(for: .seconds(5))
        label = .none
    }

    private enum LabelState {
        case success
        case unload
        case none

        var text: String {
            switch self {
            case .success: "Successfully Unloaded All Models"
            case .unload: "Unload All Models"
            case .none: "No Models Loaded"
            }
        }
    }
}
