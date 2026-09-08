//
//  BackgroundsStruct.swift
//  Astex
//
//  Created by Ben Herbert on 07/09/2026.
//
import SwiftUI

struct SelectableBackground: View {
    
    @ObservedObject var settings: Settings = Settings.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Backgrounds.allCases, id: \.self) { backgroundOption in
                let isSelected = settings.background == backgroundOption && settings.isBackgroundImageEnabled
                
                Button {
                    if backgroundOption == .none {
                        settings.isBackgroundImageEnabled = false
                    }else {
                        settings.background = backgroundOption
                        settings.isBackgroundImageEnabled = true
                    }
                    
                } label: {
                    VStack(spacing: 0) {
                        Image(backgroundOption.bg.fileName)
                            .resizable()
                            .scaledToFit()
                        
                        Text(backgroundOption.bg.name)
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 36, alignment: .center)
                    }
                    .foregroundStyle(ThemesManager.shared.getTextColour().opacity(0.8))
                    .frame(maxWidth: .infinity, minHeight: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ThemesManager.shared.getSurfaceColour().opacity(0.55))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                ThemesManager.shared.getTextColour().opacity(isSelected ? 0.65 : 0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 11)
                                .inset(by: 3)
                                .stroke(ThemesManager.shared.getTextColour().opacity(0.12), lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 200, maxHeight: 150)
                .accessibilityLabel("\(backgroundOption.bg.name) appearance")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
