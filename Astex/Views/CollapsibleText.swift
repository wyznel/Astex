//
//  CollapsibleText.swift
//  Astex
//
//  Created by Ben Herbert on 02/07/2026.
//
import SwiftUI
import Textual

struct CollapsibleText: View {
    let text: String
    let lineLimit: Int
    
    @State private var expanded = false
    @State private var truncated = false
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6){
            InlineText(markdown: text)
                .lineLimit(expanded ? nil : lineLimit)
                .background(
                    InlineText(markdown: text)
                        .lineLimit(lineLimit)
                        .background( GeometryReader { proxy in
                            Color.clear.onAppear {
                                let totalHeight = proxy.size.height
                                let singleLineHeight = NSLayoutManager().defaultLineHeight(for: NSFont.preferredFont(forTextStyle: .body))
                                truncated = totalHeight > singleLineHeight * CGFloat(lineLimit)
                            }
                        })
                        .hidden()
                )
                .animation(.spring(duration: Settings.shared.animationDelay), value: expanded)
            
            if isHovered || expanded {
                Button{
                    expanded.toggle()
                }label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                }
            }
        }
        .contentShape(Rectangle())
        .animation(.spring(duration: Settings.shared.animationDelay), value: isHovered)
        .onHover{ hovering in
            withAni {
                isHovered = hovering
            }
            
        }
    }
}
