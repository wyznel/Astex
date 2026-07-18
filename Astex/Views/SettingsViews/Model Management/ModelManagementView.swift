//
//  ModelManagementView.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import Ollama
import Textual


// MARK: - ModelManagementView

struct ModelManagementView: View {

    struct ColumnDescriptor: Identifiable {
        let id: String
        let header: String
        let keyPath: KeyPath<ModelRowData, String>
        let isVisible: (Settings) -> Bool
    }
    
    // MARK: Properties
    
    static var client = Client.default
    
    static var utilities = Utilities()

    @ObservedObject private var settings = Settings.shared
    @State private var models: [String] = []
    @State private var hasModelTableAppeared: Bool = false
    
    @State private var showTextInput: Bool = false
    
    
    @State private var successfullyUnloadedModels: Bool = false
    // MARK: Body
    
    var body: some View {
        ZStack {
            VStack {
                ModelProvider()
                
                ModelTable(showTextInput: $showTextInput, models: $models) {
                    await refreshAvailableModels()
                }
            }
            .blur(radius: showTextInput ? 5 : 0)
            
            if showTextInput {
                ModelInputCard(showTextInput: $showTextInput) {
                    Task {
                        models = await ModelManagementView.utilities.getAvailableModelsNAME_ONLY_OLLAMA()
                    }
                }
            }
        }
    }
    
    // MARK: - Model Table
    
    struct ModelTable: View {
        @ObservedObject private var settings = Settings.shared
        // MARK: Column Descriptor

        static let allColumns: [ColumnDescriptor] = [
            ColumnDescriptor(
                id: "sizeOnDisk",
                header: "Size on disk",
                keyPath: \.sizeOnDisk,
                isVisible: { $0.showSizeOnDisk }
            ),
            ColumnDescriptor(
                id: "format",
                header: "FORMAT",
                keyPath: \.format,
                isVisible: { $0.showFormat }
            ),
            ColumnDescriptor(
                id: "parameterSize",
                header: "Parameter Size",
                keyPath: \.parameterSize,
                isVisible: { $0.showParameterSize }
            ),
        ]
        @State private var selectedModel: String? = Settings.shared.selectedModel
        
        @Binding var showTextInput: Bool
        @Binding var models: [String]
        var refreshAvailableModels: () async -> Void
        
        /// Visible columns derived from current settings.
        private var visibleColumns: [ColumnDescriptor] {
            Self.allColumns.filter { $0.isVisible(settings) }
        }
        
        var body: some View {
            VStack {
                HStack {
                    InlineText(markdown: "**Models**")
                        .padding(6)
                        .frame(alignment: .leading)
                    Spacer()
                    
                    PullModelButton(showTextInput: $showTextInput)
                    
                    Refresh {
                        Task {
                            await refreshAvailableModels()
                        }
                    }
                    UnloadAllModelsButton()
                }
                .frame(maxWidth: 600)
                ///          Model List
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

                            ForEach(visibleColumns) { column in
                                Text(column.header)
                                    .gridColumnAlignment(.leading)
                            }

                            // Invisible trash icon to reserve the action column width
                            Image(systemName: "trash")
                                .opacity(0)
                        }
                        .padding(.vertical, 4)

                        Divider()

                        // Data rows
                        ForEach(models, id: \.self) { model in
                            ModelDetailsRow(
                                model: model,
                                selectedModel: $selectedModel,
                                visibleColumns: visibleColumns,
                                onDelete: {
                                    withAni {
                                        models.removeAll { $0 == model }
                                    }
                                }
                            )
                            Divider()
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
                    settings.glassEffect.interactive(),
                    in: .rect(cornerRadius: 12)
                )
                .onChange(of: selectedModel) {
                    Settings.shared.selectedModel = selectedModel ?? ""
                    print("Selected Model: \(Settings.shared.selectedModel)")
                }
            }
            .task {
                await refreshAvailableModels()
                
                if settings.selectedModel.isEmpty && !models.isEmpty {
                    settings.selectedModel = models[0]
                }
                
            }
            .contentShape(Rectangle())
            .contextMenu(
                menuItems: {
                    Button(
                        "Size on Disk",
                        systemImage: settings.showSizeOnDisk ? "checkmark" : "square"
                    ) {
                        withAni {
                            settings.showSizeOnDisk.toggle()
                        }
                    }

                    Button(
                        "Format",
                        systemImage: settings.showFormat ? "checkmark" : "square"
                    ) {
                        withAni {
                            settings.showFormat.toggle()
                        }
                    }
                    Button(
                        "Parameter Size",
                        systemImage: settings.showParameterSize ? "checkmark" : "square"
                    ) {
                        withAni{
                            settings.showParameterSize.toggle()
                        }
                    }
                })
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        }
    }
    
    // MARK: - ModelDetailsRow

    ///  Combines ModelToggle and model info columns in a single GridRow.
    struct ModelDetailsRow: View {
        let model: String
        
        var onDelete: (() -> Void)?
        
        @Binding var selectedModel: String?

        let visibleColumns: [ColumnDescriptor]

        @State private var rowData: ModelRowData

        init(
            model: String,
            selectedModel: Binding<String?>,
            visibleColumns: [ColumnDescriptor],
            onDelete: @escaping () -> Void
        ) {
            self.model = model
            self._selectedModel = selectedModel
            self.visibleColumns = visibleColumns
            self.onDelete = onDelete
            self._rowData = State(initialValue: ModelRowData(modelName: model))
        }

        var body: some View {
            GridRow {
                ModelToggle(
                    modelName: model,
                    selectedModel: $selectedModel
                )

                if rowData.isLoading {
                    // Span all data columns + the action column with a single progress indicator
                    ProgressView()
                        .gridCellColumns(visibleColumns.count + 1)
                } else {
                    ForEach(visibleColumns) { column in
                        Text(rowData[keyPath: column.keyPath])
                    }
                    
                    ModelDeleteButton(
                        modelName: model,
                        isDisabled: selectedModel == model,
                        onDelete: onDelete
                    )
                    
                    UnloadThisModel(
                        modelName: model,
                        isDisabled: selectedModel == model,
                        selectedModel: $selectedModel
                    )
                }
            }
            .padding(.vertical, 2)
            .background(
                Color.sepiaAccent.opacity(selectedModel == model ? 0.1 : 0.0),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .task {
                await rowData.loadInfo()
            }
        }
    }
    
    // MARK: - ModelDeleteButton

    /// Delete model button
    struct ModelDeleteButton: View {
        let modelName: String
        let isDisabled: Bool
        
        var onDelete: (() -> Void)?
        
        @ObservedObject private var settings = Settings.shared
        
        @State private var successInDeletionOfModel: Bool = false
        @State private var showModelDeletionAlert: Bool = false
        @State private var isPresentingConfirm: Bool = false

        var body: some View {
            Button {
                if !settings.suppressModelDeletionConfirmation {
                    isPresentingConfirm = true
                } else {
                    Task {
                        do {
                            let modelID: Model.ID = Model.ID(
                                rawValue: modelName
                            )!
                            if try await client.deleteModel(modelID) {
                                successInDeletionOfModel = true
                                onDelete?()
                            }else {
                                successInDeletionOfModel = false
                            }
                            showModelDeletionAlert = true
                        } catch {
                            print(error)
                        }
                    }
                }
            } label: {
                Image(systemName: "trash")
            }
            .tooltip {
                Text("Delete Model")
                    .fixedSize()
            }
            .disabled(isDisabled)
            .confirmationDialog(
                "Are you sure?",
                isPresented: $isPresentingConfirm
            ) {
                Button("Delete model: \(modelName)", role: .destructive) {
                    Task {
                        do {
                            let modelID = Model.ID(rawValue: modelName)
                            if try await client.deleteModel(modelID!) {
                                successInDeletionOfModel = true
                                onDelete?()
                            }else {
                                successInDeletionOfModel = false
                            }
                            showModelDeletionAlert = true
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            .dialogIcon(Image(systemName: "trash.circle.fill"))
            .dialogSuppressionToggle(
                isSuppressed: settings.$suppressModelDeletionConfirmation
            )
            .alert(isPresented: $showModelDeletionAlert) {
                Alert(title: Text(successInDeletionOfModel ?
                                  "Successfully deleted model: \(modelName)" :
                                    "Failed to delete model!"),
                      message: Text(successInDeletionOfModel ?
                                    "Removed model: \(modelName)" :
                                        "Unable to remove model: \(modelName)"),
                      dismissButton: .default(Text("OK"), action: {
                    showModelDeletionAlert = false
                }))
            }
        }
    }

    // MARK: - ModelToggle

    /// Each model must have its own toggle (bars).
    struct ModelToggle: View {
        let modelName: String

        @Binding var selectedModel: String?

        /// Derived -- no separate @State needed.
        private var isSelected: Bool {
            selectedModel == modelName
        }

        var body: some View {
            Toggle(
                modelName,
                isOn: Binding(
                    get: { selectedModel == modelName },
                    set: { isOn in
                        if isOn {
                            selectedModel = modelName
                        } else if selectedModel == modelName {
                            selectedModel = nil
                        }
                    }
                )
            )
            .disabled(isSelected)
        }
    }
    
    // MARK: - Unload All Models Button

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
        
        //        private let buttonText: [String] = ["Unload All Models", "No Models Loaded", "Successfully Unloaded All Models"]
        
        var body: some View {
            Button {
                Task {
                    if await ModelManagementView.utilities.tryUnloadAllModels() {
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
                areAnyModelsLoaded = await utilities.areAnyModelsLoaded()
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
    
    // MARK: - Unload specific model
    struct UnloadThisModel: View {
        let modelName: String
        let isDisabled: Bool
        
        @Binding var selectedModel: String?
        
        @State var isLoaded: Bool = false
        
        var body: some View {
            Button {
                if client.unloadModel(model: modelName) {
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
                if await utilities.areAnyModelsLoaded() {
                    let loadedModels = await utilities.getRunningModels()
                    
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
    
    // MARK: - Pull model
    
    struct PullModelButton: View {
        
        @Binding var showTextInput: Bool
        
        var body: some View {
            Button {
                withAni {
                    showTextInput = true
                }
            }label: {
                Image(systemName: "plus")
            }
            .tooltip(delay: 1.0, offsetX: 40) {
                Text("Pull Model from Ollama")
            }
        }
    }
    
    // MARK: - Model Input Card
    struct ModelInputCard: View {
        
        @Binding var showTextInput: Bool
        
        var onDone: () -> Void
        
        @State private var input_field = ""
        @State private var modelName = ""
        @State private var progressText: String = ""
        
        @State private var errorMessage: String?
        @State private var downloadInProgress: Bool = false
        @State private var isSuccess: Bool = false
        
        @State private var progress: Double = 0
        @State private var model_hash: String = ""
        @State private var temp_hash: String = ""
        @State private var temp_count: Int = 1
        @State private var appeared: Bool = false

        var body: some View {
            VStack(spacing: 16) {
                // Header area with icon and close button
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.sepiaAccent)
                        
                        Text("Pull Model")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.sepiaText)
                        
                        Text("Download a model from the Ollama library")
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
                    TextField("e.g. llama3.2:3b", text: $input_field)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .glassEffect(Settings.shared.glassEffect, in: .capsule)
                        .disabled(downloadInProgress)
                    
                    Button {
                        Task {
                            do {
                                modelName = input_field
                                for try await prog in client.pullModelStream("\(modelName)") {
                                    if temp_count == 2 && model_hash.isEmpty {
                                        model_hash = prog.status
                                        progressText = modelName
                                    }
                                    
                                    temp_hash = prog.status
                                    if temp_count < 2 {
                                        temp_count += 1
                                    }
                                    
                                    if model_hash != temp_hash {
                                        progressText = temp_hash
                                    }
                                    
                                    if progressText.contains("success") {
                                        isSuccess = true
                                    }
                                    
                                    if let total = prog.total, let completed = prog.completed {
                                        progress = Double(completed) / Double(total) * 100
                                    }
                                }
                            } catch {
                                print(error)
                            }
                        }
                        
                        withAni {
                            downloadInProgress = true
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
                    .disabled(input_field.isEmpty)
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
                        ProgressView(value: progress, total: 100)
                            .tint(Color.sepiaAccent)
                        
                        HStack {
                            Text(progressText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.sepiaText.opacity(0.7))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int(progress))%")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.sepiaAccent)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                if isSuccess {
                    Text("Finished downloading model: \(modelName)")
                    Button {
                        withAni {
                            downloadInProgress = false
                            showTextInput = false
                        }
                        Task {
                            onDone()
                        }
                    }label: {
                        Text("Done")
                    }
                    .task {
                        withAni {
                            downloadInProgress = false
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
    
    // MARK: - Refresh Models List
    
    func refreshAvailableModels() async {
        models = await ModelManagementView.utilities.getAvailableModelsNAME_ONLY_OLLAMA()
    }
}
