//
//  InstallEngineView.swift
//  Astex
//
//  Created by Ben Herbert on 31/07/2026.
//

import SwiftUI

/// Second page of setup
struct InstallEngineView: View {
    
    @Binding var PageIndex: Int
    
    @ObservedObject var settings = Settings.shared
    
    @State private var isContinueButtonHovered: Bool = false
    
    @State private var ollamaIsInstalled: Bool = isOllamaInstalled()
    @State private var rapidMLXIsInstalled: Bool = isRapidMLXInstalled()
    
    private var isContinueButtonDisabled: Bool {
        !ollamaIsInstalled && !rapidMLXIsInstalled
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Download a model engine")
                .font(.alanSans(25))
                .fontWeight(.bold)
            
            HStack(spacing: 30) {
                OllamaCard(isAlreadyInstalled: ollamaIsInstalled)
                RapidMLXCard(isAlreadyInstalled: rapidMLXIsInstalled)
            }
            Text("Install either Ollama or RapidMLX to get started.")
                .font(.alanSans(15))
                .fontWeight(.regular)
            
            Button {
                /// Re-check in case an engine was installed since the view appeared.
                refreshInstallState()
                
                settings.isOllamaInstalled = ollamaIsInstalled
                settings.isRapidMLXInstalled = rapidMLXIsInstalled
                
                if ollamaIsInstalled || rapidMLXIsInstalled {
                    withAni {
                        PageIndex = 3
                    }
                }
            } label: {
                Text("Continue")
                    .font(.alanSans(20))
                    .fontWeight(.regular)
                    .contentShape(Capsule())
                Image(systemName: "arrow.forward")
            }
            .disabled(isContinueButtonDisabled)
            .borderBeam(
                border: .white,
                beam: [.orange],
                beamBlur: 5,
                cornerRadius: 20,
                isEnabled: !isContinueButtonDisabled
            )
            .glassEffect(
                isContinueButtonHovered && !isContinueButtonDisabled
                ? Settings.shared.glassEffect
                    .tint(Color.sepiaAccent.opacity(0.3))
                : Settings.shared.glassEffect,
                in: Capsule()
            )
            .onHover{ hovered in
                isContinueButtonHovered = hovered
            }
            .clipShape(Capsule())
            .animation(.spring(duration: 0.25), value: isContinueButtonHovered)
        }
        .onAppear {
            refreshInstallState()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshInstallState()
        }
    }
    
    /// Re-checks the filesystem so the UI reflects engines installed while this
    /// view was off-screen (e.g. the user downloaded one in the background).
    private func refreshInstallState() {
        ollamaIsInstalled = isOllamaInstalled()
        rapidMLXIsInstalled = isRapidMLXInstalled()
    }
    
    // MARK: - Show Ollama installation card.
    struct OllamaCard: View {
        
        @Environment(\.openURL) private var openURL
        
        @State private var isCardHovered: Bool = false
        
        let isAlreadyInstalled: Bool
        
        @State private var isDownloadButtonHovered: Bool = false
        var body: some View {
            VStack {
                Image("ollama-svg")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                
                Divider()
                Text("Ollama")
                    .font(.alanSans(20))
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    Text("Ollama is the recommended choice to explore a wider variety of models.")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    
                    if !isAlreadyInstalled {
                        Button {
                            openURL(URL(string: "https://ollama.com/download")!)
                        } label: {
                            HStack {
                                Text("Open Download Page")
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .borderBeam(
                            border: .white,
                            beam: [.red],
                            beamBlur: 5,
                            cornerRadius: 6,
                        )
                        .scaleEffect(isDownloadButtonHovered ? 1.1 : 1)
                        .onHover { hovered in
                            isDownloadButtonHovered = hovered
                        }
                        .animation(.spring(duration: 0.25, bounce: 0.5), value: isDownloadButtonHovered)
                    }
                    
                    Text(isAlreadyInstalled ? "Already Installed" : "Not Installed")
                        .foregroundStyle(isAlreadyInstalled ? Color.green : Color.red)
                }
            }
            .padding(10)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .frame(width: 300, height: 280)
            .borderBeam(
                border: .white,
                beam: [isAlreadyInstalled ? .green : .red],
                beamBlur: 5,
                cornerRadius: 12,
                isEnabled: isCardHovered || isAlreadyInstalled
            )
            .glassEffect(Settings.shared.glassEffect, in: RoundedRectangle(cornerRadius: 12))
            .onHover { hovered in
                isCardHovered = hovered
            }
            .scaleEffect(isCardHovered ? 1.05 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.60), value: isCardHovered)
            .highPriorityGesture(
                TapGesture()
                    .onEnded{_ in
                        openURL(URL(string: "https://ollama.com/download")!)
                    }
            )
        }
    }
    
    // MARK: - Show RapidMLX installation card.
    struct RapidMLXCard: View {
        @Environment(\.openURL) private var openURL
        
        @State private var isCardHovered: Bool = false
        
        let isAlreadyInstalled: Bool
        
        @State private var isDownloadButtonHovered: Bool = false
        var body: some View {
            VStack {
               Image("rapid-mlx-svg")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                
                Divider()
                Text("RapidMLX")
                    .font(.alanSans(20))
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    Text("RapidMLX is the recommended choice for running LLMs on Mac. The Terminal & Server version is required.")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        
                    if !isAlreadyInstalled {
                        Button {
                            openURL(URL(string: "https://rapidmlx.com/download")!)
                        } label: {
                            HStack {
                                Text("Open Download Page")
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .borderBeam(
                            border: .white,
                            beam: [.red],
                            beamBlur: 5,
                            cornerRadius: 6,
                        )
                        .scaleEffect(isDownloadButtonHovered ? 1.1 : 1)
                        .onHover { hovered in
                            isDownloadButtonHovered = hovered
                        }
                        .animation(.spring(duration: 0.25, bounce: 0.5), value: isDownloadButtonHovered)
                    }
                    
                    Text(isAlreadyInstalled ? "Already Installed" : "Not Installed")
                        .foregroundStyle(isAlreadyInstalled ? Color.green : Color.red)
                }
                
            }
            .padding(10)
            .frame(width: 300, height: 280)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .borderBeam(
                border: .white,
                beam: [isAlreadyInstalled ? .green : .red],
                beamBlur: 5,
                cornerRadius: 12,
                isEnabled: isCardHovered || isAlreadyInstalled
            )
            .glassEffect(Settings.shared.glassEffect, in: RoundedRectangle(cornerRadius: 12))
            .onHover { hovered in
                isCardHovered = hovered
            }
            .scaleEffect(isCardHovered ? 1.05 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.60), value: isCardHovered)
            .highPriorityGesture(
                TapGesture()
                    .onEnded{_ in
                        openURL(URL(string: "https://rapidmlx.com/download")!)
                    }
            )

        }
    }
}
