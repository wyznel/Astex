//
//  ModelInputCard.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import Ollama

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
                            for try await prog in Utilities.shared.client.pullModelStream("\(modelName)") {
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
                } label: {
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
