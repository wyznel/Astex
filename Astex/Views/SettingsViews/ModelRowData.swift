//
//  ModelRowData.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import Foundation

/// Lightweight view model that owns the async fetch, formatting,
/// and loading state for a single model row.
@MainActor
@Observable
final class ModelRowData {

    let modelName: String

    private(set) var sizeOnDisk: String = "--"
    private(set) var format: String = "--"
    private(set) var parameterSize: String = "--"
    private(set) var isLoading: Bool = true

    private static let utilities = Utilities()

    init(modelName: String) {
        self.modelName = modelName
    }

    /// Fetches model metadata from Ollama and populates formatted display strings.
    func loadInfo() async {
        let info = await Self.utilities.getModelInfo(model: modelName)

        let rawSize = info["size"] as? Double ?? 0
        let sizeInGB = Double(round(100 * (rawSize / 1_000_000_000)) / 100)
        sizeOnDisk = "\(sizeInGB) GB"

        format = info["format"] as? String ?? "Unknown"
        parameterSize = info["parameter_size"] as? String ?? "0"

        isLoading = false
    }
}
