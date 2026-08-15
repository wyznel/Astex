//
//  ModelDetailsRow.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI

/// Combines ModelToggle and model info columns in a single GridRow.
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
