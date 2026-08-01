//
//  DownloadModelView.swift
//  Astex
//
//  Created by Ben Herbert on 01/08/2026.
//

import SwiftUI
import Ollama
import RapidMLX

struct DownloadModelView: View {
    @Binding var PageIndex: Int
    @ObservedObject var settings = Settings.shared
    
    @State private var isContinueButtonHovered: Bool = false
    @State private var isSkipButtonHovered: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                if settings.isOllamaInstalled {
                    OllamaDownloadModelView(PageIndex: $PageIndex)
                }
                if settings.isRapidMLXInstalled {
                    RapidMLXDownloadModelView(PageIndex: $PageIndex)
                }
            }
            
            Text("""
                Once you start downloading a model, you can continue. Astex will notify you when the download is complete. 
                
                If you're not ready to download a model yet, you can always do this later in the settings menu.
                """)
                .font(.alanSans(14))
                .frame(maxWidth: 550)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                
            Button {
                sendNotification(title: "Model has finished downloading", body: "The model: 'tinyllama:1.1b' has finished downloading.")
            } label: {
                HStack {
                    Text("Continue")
                        .font(.alanSans(20))
                        .fontWeight(.regular)
                        .contentShape(Capsule())
                    Image(systemName: "arrow.right")
                }
            }
            .borderBeam(
                border: .white,
                beam: [.orange],
                beamBlur: 5,
                cornerRadius: 20,
                isEnabled: !isContinueButtonHovered
            )
            .glassEffect(
                isContinueButtonHovered
                ? Settings.shared.glassEffect
                    .tint(Color.sepiaAccent.opacity(0.3))
                : Settings.shared.glassEffect,
                in: Capsule()
            )
            .onHover { isHovered in
                isContinueButtonHovered = isHovered
            }
            .animation(.spring(duration: 0.25, bounce: 0.5), value: isContinueButtonHovered)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            /// Skip ahead
            Button {
                
            }label: {
                Text("Skip")
                    .font(.alanSans(15))
                    .fontWeight(.regular)
                    .contentShape(Capsule())
                Image(systemName: "chevron.right.dotted.chevron.right")
            }
            .borderBeam(
                border: .white,
                beam: [.orange],
                beamBlur: 5,
                cornerRadius: 20,
                isEnabled: !isSkipButtonHovered
            )
            .glassEffect(
                isSkipButtonHovered
                ? Settings.shared.glassEffect
                    .tint(Color.sepiaAccent.opacity(0.3))
                : Settings.shared.glassEffect,
                in: Capsule()
            )
            .onHover { isHovered in
                isSkipButtonHovered = isHovered
            }
            .animation(.spring(duration: 0.25, bounce: 0.5), value: isSkipButtonHovered)
            .clipShape(Capsule())
            .offset(x: -25)
        }
    }
}

private struct OllamaDownloadModelView: View {
    @Binding var PageIndex: Int
    
    @State private var isCardHovered: Bool = false
    
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
    
    var utilities = Utilities()
    
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
                            for try await prog in utilities.client.pullModelStream("\(modelName)") {
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
        .frame(width: 320, height: 250)
        .glassEffect(Settings.shared.glassEffect, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .onHover { hovered in
            isCardHovered = hovered
            
        }
        .scaleEffect(isCardHovered ? 1.05 : 1)
        .animation(.spring(duration: 0.25, bounce: 0.5), value: isCardHovered)
    }
}

private struct RapidMLXDownloadModelView: View {
    
    @Binding var PageIndex: Int
    
    @State private var input_field = ""
    @State private var modelName = ""
    
    @State private var errorMessage: String?
    @State private var downloadInProgress: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isCardHovered: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            // Header area with icon and close button
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.sepiaAccent)
                    
                    Text("Pull RapidMLX Model")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.sepiaText)
                    
                    Text("Download a model using RapidMLX")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.sepiaText.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            
            HStack(spacing: 8) {
                TextField("e.g. gemma-4-e2b-4bit", text: $input_field)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect(Settings.shared.glassEffect, in: .capsule)
                    .disabled(downloadInProgress)
                
                Button {
                    modelName = input_field
                    errorMessage = nil
                    withAni {
                        downloadInProgress = true
                    }
                    Task {
                        do {
                            try await ModelManagementView.rapidmlxClient.pull(
                                alias: modelName,
                                hfRepo: nil
                            )
                            withAni {
                                isSuccess = true
                                downloadInProgress = false
                            }
                        } catch {
                            withAni {
                                errorMessage = error.localizedDescription
                                downloadInProgress = false
                            }
                        }
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
                .disabled(input_field.isEmpty || downloadInProgress)
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
                    ProgressView()
                        .tint(Color.sepiaAccent)
                    
                    Text("Downloading model: \(modelName)...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.sepiaText.opacity(0.7))
                        .lineLimit(1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if isSuccess {
                VStack(spacing: 8) {
                    Text("Finished downloading model: \(modelName)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sepiaText)
                    
                    Button {
                        
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 320, height: 250)
        .glassEffect(Settings.shared.glassEffect, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .onHover { hovered in
            isCardHovered = hovered
            
        }
        .scaleEffect(isCardHovered ? 1.05 : 1)
        .animation(.spring(duration: 0.25, bounce: 0.5), value: isCardHovered)
    }
}
