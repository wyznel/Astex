//
//  ModelDeleteButton.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import Ollama

/// Delete model button
struct ModelDeleteButton: View {
    let modelName: String
    let isDisabled: Bool

    var onDeleteAsync: (() async throws -> Bool)? = nil
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
                    await performDelete()
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
                    await performDelete()
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

    private func performDelete() async {
        do {
            let success: Bool
            if let onDeleteAsync {
                success = try await onDeleteAsync()
            } else {
                let modelID = Ollama.Model.ID(rawValue: modelName)
                success = try await Utilities.shared.client.deleteModel(modelID!)
            }
            if success {
                successInDeletionOfModel = true
                onDelete?()
            } else {
                successInDeletionOfModel = false
            }
            showModelDeletionAlert = true
        } catch {
            print(error)
            successInDeletionOfModel = false
            showModelDeletionAlert = true
        }
    }
}
