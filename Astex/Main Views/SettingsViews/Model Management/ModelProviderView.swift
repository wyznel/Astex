//
//  ModelProviderView.swift
//  Astex
//
//  Created by Ben Herbert on 18/07/2026.
//
import SwiftUI

struct ModelProvider: View {

    @ObservedObject private var settings = Settings.shared

    @State private var clicked: Bool = false
    
    private let providers: [ModelEngines] = ModelEngines.allCases

    var body: some View {
        VStack(alignment: .leading){
            Text("Select Model Engine")
                .font(.headline)
            HStack(spacing: 12) {
                Text("Engine")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)

                Spacer(minLength: 8)

                Button {
                    withAni {
                        clicked = true
                    }
                    settings.modelProvider = .ollama
                    clicked = false
                }label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .foregroundStyle(Color.sepiaAccent)
                        .rotationEffect(.degrees(clicked ? -360 : 0))
                }
                .buttonStyle(.plain)
                .tooltip(delay: 1.0, offsetX: 75) {
                    Text("Reset to default model engine (Ollama)")
                        .fixedSize()
                }
                Picker("Engine", selection: $settings.modelProvider) {
                    ForEach(providers, id: \.self) { provider in
                        Text(provider.rawValue)
                            .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(settings.glassEffect.tint(Color.sepiaBackground.opacity(0.5)), in: .rect(cornerRadius: 10))
            .frame(maxWidth: 600)
        }

    }
}
