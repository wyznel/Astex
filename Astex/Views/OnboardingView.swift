//
//  OnboardingView.swift
//  Astex
//
//  Created by Ben Herbert on 13/07/2026.
//
import SwiftUI
import Textual

struct OnboardingView: View {
    
    @State private var PageIndex: Int = 1
    
    var body: some View {
        ZStack {
            BackgroundDecoration()
                .ignoresSafeArea()
            if PageIndex == 1 {
                StageOne(PageIndex: $PageIndex)
                    .background(
                        Color.sepiaSurface,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            if PageIndex == 2 {
                StageTwo(PageIndex: $PageIndex)
                    .task {
                        withAni {
                            PageIndex = 2
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if PageIndex == 2 {
                            Button {
                                withAni {
                                    Settings.shared.isFirstOpen = false
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
                    }
            }
            
            if PageIndex == 3 {
                StageThree()
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
                        PageIndex = 2
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
                
                if !isOllamaInstalled() {
                    installOllamaCard(PageIndex: $PageIndex)
                } else{
                    ollamaAlreadyPresentCard(PageIndex: $PageIndex)
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
        
        struct ollamaAlreadyPresentCard: View {
            
            @Binding var PageIndex: Int
            
            var body: some View {
                Text("Seems like you already have Ollama!")
                    .font(Font.system(size: 25, weight: .bold))
                
                InlineText(markdown:
                    """
                    \n
                    As you already have Ollama installed, feel free to skip ahead and go straight to the app.
                    """)
                .multilineTextAlignment(.center)
            }
        }
    }
    
    struct StageThree: View {
        
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
                orbitingBlob(size: 300, opacity: 0.25, radius: 140, duration: 6, clockwise: true, offsetX: 0)
                orbitingBlob(size: 250, opacity: 0.2, radius: 110, duration: 3, clockwise: false, offsetX: 0)
                orbitingBlob(size: 200, opacity: 0.15, radius: 90, duration: 4, clockwise: true, offsetX: 0)
                orbitingBlob(size: 350, opacity: 0.5, radius: 160, duration: 7, clockwise: false, offsetX: -300)
                orbitingBlob(size: 350, opacity: 0.5, radius: 160, duration: 7, clockwise: true, offsetX: 300)
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
                    .linear(duration: duration).repeatForever(autoreverses: false),
                    value: rotate
                )
        }
    }
}
