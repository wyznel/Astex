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
    // MARK: Column Descriptor
    
    /// Single source of truth for which data columns are visible and their header labels.
    struct ColumnDescriptor: Identifiable {
        let id: String
        let header: String
        let keyPath: KeyPath<ModelRowData, String>
        let isVisible: (Settings) -> Bool
    }

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

    // MARK: Properties
    
    static var client = Client.default
    
    static var utilities = Utilities()

    @ObservedObject private var settings = Settings.shared

    @State private var models: [String] = []

    @State private var selectedModel: String? = Settings.shared.selectedModel
    
    @State private var hasModelTableAppeared: Bool = false
    /// Visible columns derived from current settings.
    private var visibleColumns: [ColumnDescriptor] {
        Self.allColumns.filter { $0.isVisible(settings) }
    }

    // MARK: Body
    
    @State private var successfullyUnloadedModels: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                InlineText(markdown: "**Models**")
                    .padding(6)
                    .frame(alignment: .leading)
                Spacer()
                
                UnloadAllModelsButton()
            }
            .frame(maxWidth: 600)
///          Model List
            VStack(alignment: .leading) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
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
            .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 12))
            .onChange(of: selectedModel) {
                Settings.shared.selectedModel = selectedModel ?? ""
                print("Selected Model: \(Settings.shared.selectedModel)")
            }
        }
        .task {
            models = await ModelManagementView.utilities.getAvailableModelsNAME_ONLY_OLLAMA()
        }
        .contentShape(Rectangle())
        .contextMenu(menuItems: {
            Button("Size on Disk", systemImage: settings.showSizeOnDisk ? "checkmark" : "square") {
                withAni {
                    settings.showSizeOnDisk.toggle()
                }
            }

            Button("Format", systemImage: settings.showFormat ? "checkmark" : "square") {
                withAni {
                    settings.showFormat.toggle()
                }
            }
            Button("Parameter Size", systemImage: settings.showParameterSize ? "checkmark" : "square") {
                withAni{
                    settings.showParameterSize.toggle()
                }
            }
        })
    }


    // MARK: - ModelDetailsRow

///  Combines ModelToggle and model info columns in a single GridRow.
    struct ModelDetailsRow: View {
        let model: String
        
        var onDelete: (() -> Void)?
        
        @Binding var selectedModel: String?

        let visibleColumns: [ColumnDescriptor]

        @State private var rowData: ModelRowData

        init(model: String, selectedModel: Binding<String?>, visibleColumns: [ColumnDescriptor], onDelete: @escaping () -> Void) {
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

/// Delete model button, extracted for clarity.
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
                        let modelID: Model.ID = Model.ID(rawValue: modelName)!
                        if try await client.deleteModel(modelID) {
                            successInDeletionOfModel = true
                            onDelete?()
                        }else {
                            successInDeletionOfModel = false
                        }
                        showModelDeletionAlert = true
                    }
                }
            } label: {
                Image(systemName: "trash")
            }
            .hoverHelpMenu {
                Text("Delete Model")
                    .fixedSize()
            }
            .disabled(isDisabled)
            .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm) {
                Button("Delete model: \(modelName)", role: .destructive) {
                    Task {
                        let modelID = Model.ID(rawValue: modelName)
                        if try await client.deleteModel(modelID!) {
                            successInDeletionOfModel = true
                            onDelete?()
                        }else {
                            successInDeletionOfModel = false
                        }
                        showModelDeletionAlert = true
                    }
                }
            }
            .dialogIcon(Image(systemName: "trash.circle.fill"))
            .dialogSuppressionToggle(isSuppressed: settings.$suppressModelDeletionConfirmation)
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
            .hoverHelpMenu(alignment: .top){
                Text("Unload Model")
            }
        }
    }
}
