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

    static var utilities = Utilities()

    @ObservedObject private var settings = Settings.shared

    @State private var models: [String] = []

    @State private var selectedModel: String? = Settings.shared.selectedModel

    /// Visible columns derived from current settings.
    private var visibleColumns: [ColumnDescriptor] {
        Self.allColumns.filter { $0.isVisible(settings) }
    }

    // MARK: Body

    var body: some View {
        VStack {
            InlineText(markdown: "**Models**")
                .padding(6)
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
                            visibleColumns: visibleColumns
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

            Button {
                settings.suppressModelDeletionConfirmation.toggle()
            } label: {
                Image(systemName: settings.suppressModelDeletionConfirmation ? "checkmark.square" : "cross")
            }
        }
        .task {
            models = await ModelManagementView.utilities.getAvailableModelsNAME_ONLY_OLLAMA()
        }
        .contentShape(Rectangle())
        .contextMenu(menuItems: {
            Button("Size on Disk", systemImage: settings.showSizeOnDisk ? "checkmark" : "square") {
                withAnimation(.spring(duration: settings.animationDelay)){
                    settings.showSizeOnDisk.toggle()
                }
            }

            Button("Format", systemImage: settings.showFormat ? "checkmark" : "square") {
                withAnimation(.spring(duration: settings.animationDelay)){
                    settings.showFormat.toggle()
                }
            }
            Button("Parameter Size", systemImage: settings.showParameterSize ? "checkmark" : "square") {
                withAnimation(.spring(duration: settings.animationDelay)){
                    settings.showParameterSize.toggle()
                }
            }
        })
    }


    // MARK: - ModelDetailsRow

///  Combines ModelToggle and model info columns in a single GridRow.
    struct ModelDetailsRow: View {
        let model: String

        @Binding var selectedModel: String?

        let visibleColumns: [ColumnDescriptor]

        @State private var rowData: ModelRowData

        init(model: String, selectedModel: Binding<String?>, visibleColumns: [ColumnDescriptor]) {
            self.model = model
            self._selectedModel = selectedModel
            self.visibleColumns = visibleColumns
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
                        isDisabled: selectedModel == model
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

        @ObservedObject private var settings = Settings.shared

        @State private var isPresentingConfirm: Bool = false

        var body: some View {
            Button {
                if !settings.suppressModelDeletionConfirmation {
                    isPresentingConfirm = true
                } else {
                    print("Deleted model: \(modelName)")
                }
            } label: {
                Image(systemName: "trash")
            }
            .disabled(isDisabled)
            .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm) {
                Button("Delete model: \(modelName)", role: .destructive) {
                    print("Confirmation of deletion of model: \(modelName)")
                    isPresentingConfirm = false
                }
            }
            .dialogIcon(Image(systemName: "trash.circle.fill"))
            .dialogSuppressionToggle(isSuppressed: settings.$suppressModelDeletionConfirmation)
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
}
