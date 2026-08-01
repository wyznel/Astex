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
    
    @State private var ShowInstallEngineView: Bool = false
    
    var body: some View {
        ZStack {
            BackgroundDecoration()
                .ignoresSafeArea()
            
            switch PageIndex {
            case 1:
                WelcomeStage(PageIndex: $PageIndex, ShowInstallEngineView: $ShowInstallEngineView)
                    .opacity(ShowInstallEngineView ? 0 : 1)
                    .animation(.spring(duration: 0.75), value: !ShowInstallEngineView)
            case 2:
                InstallEngineView(PageIndex: $PageIndex)
                    .scaleEffect(ShowInstallEngineView ? 1 : 0)
                    .opacity(ShowInstallEngineView ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.5), value: ShowInstallEngineView)
            case 3:
                DownloadModelView(PageIndex: $PageIndex)
                
            default: EmptyView()
            }
            
            VStack{
                Spacer()
                ProgressDots()
                    .offset(y: -10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sepiaBackground)
        .onKeyPress(keys: [.rightArrow], phases: .down) { keyPress in
            withAni {
                PageIndex += 1
            }
            return .handled
        }
        .onKeyPress(keys: [.leftArrow], phases: .down) { keyPress in
            withAni {
                PageIndex -= 1
            }
            return .handled
        }
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
    
    // MARK: - Welcome Menu.
    
    struct WelcomeStage: View {
        
        @Binding var PageIndex: Int
        @Binding var ShowInstallEngineView: Bool
        
        @State private var isGetStartedButtonHovered = false
        
        @State private var toggle = false
        @State private var finish = false
        var body: some View {
            VStack {
                if !toggle {
                    Text("Astex")
                        .foregroundColor(.white)
                        .font(.alanSans(40))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.sepiaText)
                        .scaleEffect(toggle ? 0.0 : 1)
                        .animation(.spring(duration: 0.5), value: toggle)
                }

                Button {
                    Task {
                        
                        withAnimation(.spring(duration: 0.50, bounce: 0.75)) {
                            toggle = true
                        }
                        
                        try? await Task.sleep(for: .seconds(1))
                        
                        withAnimation(.spring(duration: 0.25, bounce: 0.5)) {
                            finish = true
                        }
                        
                        try? await Task.sleep(for: .seconds(0.50))
                        PageIndex = 2
                        try? await Task.sleep(for: .seconds(0.05))
                        ShowInstallEngineView = true
                    }
                    isGetStartedButtonHovered = false
                } label: {
                    Text("Get started")
                        .font(.alanSans(20))
                        .fontWeight(.regular)
                        .contentShape(Capsule())
                    Image(systemName: "arrow.right")
                }
                .borderBeam(
                    border: .white,
                    beam: [.orange],
                    beamBlur: 5,
                    cornerRadius: 20,
                    isEnabled: !isGetStartedButtonHovered
                )
                .glassEffect(
                    isGetStartedButtonHovered
                    ? Settings.shared.glassEffect
                        .tint(Color.sepiaAccent.opacity(0.3))
                    : Settings.shared.glassEffect,
                    in: Capsule()
                )
                .onHover { isHovered in
                    if !toggle {
                        isGetStartedButtonHovered = isHovered
                    }
                }
                .animation(.spring(duration: 0.25, bounce: 0.5), value: isGetStartedButtonHovered)
                .clipShape(Capsule())
                
            }
            .padding(20)
            .frame(maxHeight: 175)
            .glassEffect(
                Settings.shared.glassEffect,
                in: .rect(cornerRadius: 12)
            )
            .scaleEffect(finish ? 0.0 : 1)
            .animation(.spring(duration: 0.5), value: finish)
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
