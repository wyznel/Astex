//
//  InstallEngineView.swift
//  Astex
//
//  Created by Ben Herbert on 31/07/2026.
//

import SwiftUI

var utilities = Utilities()

/// Second page of setup
struct InstallEngineView: View {
    
    @Binding var PageIndex: Int
    
    @ObservedObject var settings = Settings.shared
    
    @State private var isContinueButtonHovered: Bool = false
    @State private var isContinueButtonDisabled: Bool = !isOllamaInstalled() && !isRapidMLXInstalled()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                OllamaCard(isContinueButtonDisabled: $isContinueButtonDisabled)
                RapidMLXCard(isContinueButtonDisabled: $isContinueButtonDisabled)
            }
            Text("Install either Ollama or RapidMLX to get started.")
                .font(.alanSans(15))
                .fontWeight(.regular)
            
            Button {
                /// check if either ollama or rapidmlx has been installed
                
                settings.isOllamaInstalled = isOllamaInstalled()
                settings.isRapidMLXInstalled = isRapidMLXInstalled()
                
                let isAnEngineInstalled = settings.isOllamaInstalled || settings.isRapidMLXInstalled
                
                if isAnEngineInstalled {
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
    }
    
    // MARK: - Show Ollama installation card.
    struct OllamaCard: View {
        
        @Environment(\.openURL) private var openURL
        
        @State private var isCardHovered: Bool = false
        
        @Binding var isContinueButtonDisabled: Bool
        
        @State private var isAlreadyInstalled: Bool = isOllamaInstalled()
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
                        withAni {
                            isContinueButtonDisabled = false
                        }
                    }
            )
        }
    }
    
    // MARK: - Show RapidMLX installation card.
    struct RapidMLXCard: View {
        @Environment(\.openURL) private var openURL
        
        @State private var isCardHovered: Bool = false
        @Binding var isContinueButtonDisabled: Bool
        
        @State private var isAlreadyInstalled: Bool = isRapidMLXInstalled()
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
                    Text("RapidMLX is the recommended choice for running LLMs on Mac")
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
                        withAni {
                            isContinueButtonDisabled = false
                        }
                    }
            )

        }
    }
}
