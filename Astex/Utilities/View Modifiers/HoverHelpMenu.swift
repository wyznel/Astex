//
//  HoverInfo.swift
//  Astex
//
//  Created by Ben Herbert on 30/06/2026.
//
import SwiftUI

struct HoverHelpMenu<HoverContent: View>: ViewModifier {
    @State private var isHovering: Bool = false
    @State private var showHelp: Bool = false
    
    let delay: Double
    let alignment: Alignment
    let hoverContent: () -> HoverContent
    
    func body(content: Content) -> some View {
        content
            .onHover{ hovering in
                isHovering = hovering
                
                if hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if isHovering {
                            withAnimation(.spring(duration: Settings.shared.animationDelay)) {
                                showHelp = true
                            }
                        }
                    }
                } else {
                    withAnimation(.spring(duration: Settings.shared.animationDelay)){
                        showHelp = false
                    }
                }
            }
            .overlay(alignment: alignment) {
                if showHelp {
                    hoverContent()
                        .padding(8)
                        .fixedSize()
                        .glassEffect(.regular)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(radius: 4)
                        .offset(y: 0)
                        .offset(x: +60)
                        .transition(.opacity.combined(with: .scale))
                }
            }
    }
}


extension View {
    func hoverHelpMenu<Content: View>(
        delay: Double = 0.6,
        alignment: Alignment = .top,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(HoverHelpMenu(delay: delay, alignment: alignment, hoverContent: content))
    }
}
