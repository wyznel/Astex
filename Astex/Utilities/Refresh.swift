//
//  Refresh.swift
//  Astex
//
//  Created by Ben Herbert on 01/07/2026.
//
import SwiftUI

struct Refresh: View {
    
    let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "arrow.counterclockwise")
        }
    }
    
}
