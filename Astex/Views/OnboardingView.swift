//
//  OnboardingView.swift
//  Astex
//
//  Created by Ben Herbert on 13/07/2026.
//
import SwiftUI
import Textual
import Ollama

struct OnboardingView: View {
    
    @State private var PageIndex: Int = 1
    
    var body: some View {
        ZStack {
            BackgroundDecoration()
                .ignoresSafeArea()
            
            switch PageIndex {
            case 1:
                StageOne(PageIndex: $PageIndex)
                    .background(
                        Color.sepiaSurface,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            case 2:
                StageTwo(PageIndex: $PageIndex)
                    .task {
                        withAni {
                            PageIndex = 2
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        
                        Button {
                            withAni {
                                PageIndex = 3
                            }
                        }label: {
                            HStack(spacing: 0) {
                                Text("Skip Setup")
                                Image(systemName: "arrow.forward")
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .offset(x: -4, y: 4)
                        
                    }
            case 3:
                StageThree(PageIndex: $PageIndex)
                
            case 4:
                StageFour()
            default:
                EmptyView()
            }
    
            VStack{
                Spacer()
                ProgressDots()
                    .offset(y: -10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sepiaBackground)
    }
    
    @ViewBuilder
    func ProgressDots() -> some View {
        HStack(spacing: 10){
            ForEach(1..<4, id: \.self){ index in
                Circle()
                    .frame(width: 5, height: 5)
                    .foregroundStyle(
                        PageIndex == index ? Color.sepiaAccent : Color.gray
                    )
            }
        }
    }
    
    //MARK: - Stage One, Lets Get Started
    struct StageOne: View {
        
        @Binding var PageIndex: Int
        @State private var isHovering: Bool = false
        
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(maxWidth: 75)
                    .frame(height: 2)
                    .foregroundStyle(Color.sepiaAccent.opacity(0.4))
                Text("Astex")
                    .font(Font.system(size: 40, weight: .bold))
                
                Button {
                    withAni {
                        Task {
                            let modelCount: Int = await Utilities().getAvailableModelsNAME_ONLY_OLLAMA().count
                             
                            if isOllamaInstalled() && modelCount > 0 {
                                withAni {
                                    Settings.shared.isFirstOpen = false
                                }
                            }
                            else if isOllamaInstalled() && modelCount == 0 {
                                withAni {
                                    PageIndex = 3
                                }
                            } else{
                                withAni {
                                    PageIndex = 2
                                }
                            }
                        }
                    }

                }label: {
                    HStack {
                        Label("Lets get started", systemImage: "arrow.forward")
                    }
                    .padding(12)
                    .foregroundStyle(Color.sepiaText)
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .opacity(isHovering ? 0.85 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovering = hovering
                    }
                }
                .glassEffect(
                    Settings.shared.glassEffect
                        .interactive()
                        .tint(Color.sepiaAccent.opacity(0.75)),
                    in: .rect(cornerRadius: 12)
                )
                
            }
            .padding(.top, 28)
            .padding(.bottom, 28)
            .padding(.leading, 32)
            .padding(.trailing, 32)
            .glassEffect(
                Settings.shared.glassEffect,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
   
    //MARK: - Stage Two, Lets Get Started
    struct StageTwo: View {
        
        @Binding var PageIndex: Int
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(maxWidth: 75)
                    .frame(height: 2)
                    .foregroundStyle(Color.sepiaAccent.opacity(0.4))
                
                if isOllamaInstalled() {
                    installOllamaCard(PageIndex: $PageIndex)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 28)
            .padding(.leading, 32)
            .padding(.trailing, 32)
            .glassEffect(
                Settings.shared.glassEffect,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        
        struct installOllamaCard: View {
            
            @Binding var PageIndex: Int
            @State private var showContinueButton: Bool = false
            
            var body: some View {
                Text("Install Ollama")
                    .font(Font.system(size: 30, weight: .bold))
                
                InlineText(markdown:
                    """
                    \n
                    Astex talks to local LLMs via Ollama, and you don't have it!\nClick to go to the download page:
                    """)
                .multilineTextAlignment(.center)
                
                Link(destination: URL(string: "https://ollama.com/download")!) {
                    Text("ollama.com")
                        .foregroundColor(.sepiaText)
                        .padding()
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .glassEffect(
                    Settings.shared.glassEffect
                        .tint(Color.sepiaAccent.opacity(0.75)),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        withAni {
                            showContinueButton = true
                        }
                    }
                )
                
                if showContinueButton {
                    Button {
                        withAni {
                            PageIndex = 3
                        }
                    } label: {
                        Text("Done?")
                        Image(systemName: "arrow.forward")
                    }
                }
            }
        }
    }
    
    // MARK: - Downloading first model.
    struct StageThree: View {
        
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
        
        private var client = Client(host: URL(string: Settings.shared.ollamaURL)!, userAgent: "RapidMLX/1.0")
        
        @Binding var PageIndex: Int
        
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
                            PageIndex = 4
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text("Skip Setup")
                            Image(systemName: "arrow.forward")
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .offset(x: -4, y: 4)
                    
                    
                }
                
                HStack(spacing: 8) {
                    TextField("e.g. gemma4:e2b", text: $input_field)
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
                                for try await prog in client
                                    .pullModelStream("\(modelName)") {
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
                                        progress = Double(completed) / Double(
                                            total
                                        ) * 100
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
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .semibold,
                                        design: .monospaced
                                    )
                                )
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
                            PageIndex = 4
                        }
                    }label: {
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
            .glassEffect(
                Settings.shared.glassEffect,
                in: .rect(cornerRadius: 18)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    struct StageFour: View {
        
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(maxWidth: 75)
                    .frame(height: 2)
                    .foregroundStyle(Color.sepiaAccent.opacity(0.4))
                Text("Ready to go?")
                    .font(Font.system(size: 30, weight: .bold))
                InlineText(markdown: """
                    \nAstex will handle loading models when needed.\n
                    Haven't installed a model? See [Ollama.com](https://ollama.com/)
                    """)
                .multilineTextAlignment(.center)
                
                Button {
                    withAni {
                        Settings.shared.isFirstOpen = false
                    }
                }label: {
                    Text("Go")
                    Image(systemName: "arrow.forward")
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 28)
            .padding(.leading, 32)
            .padding(.trailing, 32)
            .glassEffect(
                Settings.shared.glassEffect,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
    
    //MARK: - Background Decoration
    
    struct BackgroundDecoration: View {

        @State private var rotate = false

        var body: some View {
            ZStack {
                orbitingBlob(
                    size: 300,
                    opacity: 0.25,
                    radius: 140,
                    duration: 6,
                    clockwise: true,
                    offsetX: 0
                )
                orbitingBlob(
                    size: 250,
                    opacity: 0.2,
                    radius: 110,
                    duration: 3,
                    clockwise: false,
                    offsetX: 0
                )
                orbitingBlob(
                    size: 200,
                    opacity: 0.15,
                    radius: 90,
                    duration: 4,
                    clockwise: true,
                    offsetX: 0
                )
                orbitingBlob(
                    size: 350,
                    opacity: 0.5,
                    radius: 160,
                    duration: 7,
                    clockwise: false,
                    offsetX: -300
                )
                orbitingBlob(
                    size: 350,
                    opacity: 0.5,
                    radius: 160,
                    duration: 7,
                    clockwise: true,
                    offsetX: 300
                )
            }
            .onAppear {
                rotate = true
            }
        }

        private func orbitingBlob(size: CGFloat, opacity: Double, radius: CGFloat, duration: Double, clockwise: Bool, offsetX: Double) -> some View {
            Circle()
                .fill(Color.sepiaAccent.opacity(opacity))
                .frame(width: size, height: size)
                .blur(radius: size * 0.25)
                .offset(x: offsetX, y: -radius)
                .rotationEffect(.degrees(rotate ? (clockwise ? 360 : -360) : 0))
                .animation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false),
                    value: rotate
                )
        }
    }
}
