//
//  ColumnDescriptor.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

/// Describes a single optional column in the Ollama model table.
struct ColumnDescriptor: Identifiable {
    let id: String
    let header: String
    let keyPath: KeyPath<ModelRowData, String>
    let isVisible: (Settings) -> Bool
}
