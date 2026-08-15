//
//  OllamaModelTable.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import Textual

// MARK: - Ollama Model Table

struct OllamaModelTable: View {
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
                InlineText(markdown: "**Ollama Models**")
                    .padding(6)
                    .frame(alignment: .leading)
                Spacer()

                PullModelButton(showTextInput: $showTextInput, tooltipText: "Pull Model from Ollama")

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
                settings.glassEffect,
                in: .rect(cornerRadius: 12)
            )
            .onChange(of: selectedModel) {
                Settings.shared.selectedModel = selectedModel ?? ""
                print("Selected Model: \(Settings.shared.selectedModel)")
            }
            .onChange(of: settings.selectedModel) {
                selectedModel = settings.selectedModel
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
        .frame(maxWidth: .infinity, alignment: .top)

    }
}

struct PullModelButton: View {

    @Binding var showTextInput: Bool
    var tooltipText: String = "Pull Model from Ollama"

    var body: some View {
        Button {
            withAni {
                showTextInput = true
            }
        } label: {
            Image(systemName: "plus")
        }
        .tooltip(delay: 1.0, offsetX: 40) {
            Text(tooltipText)
        }
    }
}
