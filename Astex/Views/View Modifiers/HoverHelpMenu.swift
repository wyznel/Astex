//
//  HoverInfo.swift
//  Astex
//
//  Created by Ben Herbert on 30/06/2026.
//
import SwiftUI

struct ToolTip<HoverContent: View>: ViewModifier {
    @State private var isHovering: Bool = false
    @State private var showHelp: Bool = false
    
    let delay: Double
    let alignment: Alignment
    let offsetX: Double
    let hoverContent: () -> HoverContent
    
    func body(content: Content) -> some View {
        content
            .onHover{ hovering in
                isHovering = hovering
                
                if hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if isHovering {
                            withAni {
                                showHelp = true
                            }
                        }
                    }
                } else {
                    withAni {
                        showHelp = false
                    }
                }
            }
            .overlay(alignment: alignment) {
                if showHelp {
                    hoverContent()
                        .padding(8)
                        .fixedSize()
                        .background(Capsule().fill(Color.sepiaSurface))
                        .overlay(
                            Capsule()
                                .strokeBorder(.separator.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(radius: 4)
                        .offset(y: 0)
                        .offset(x: +60+offsetX)
                        .transition(.opacity.combined(with: .scale))
                }
            }
    }
}


extension View {
    func tooltip<Content: View>(
        delay: Double = 0.6,
        alignment: Alignment = .top,
        offsetX: Double = 0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ToolTip(delay: delay, alignment: alignment, offsetX: offsetX,hoverContent: content))
    }
}
