//
//  ModelToggle.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI

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
