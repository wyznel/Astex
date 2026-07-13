//
//  UploadedFileView.swift
//  Astex
//
//  Created by Ben Herbert on 12/07/2026.
//
import SwiftUI

struct UploadedFileView: View {
    let url: URL
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Image(systemName: "text.document")
            Text(url.lastPathComponent)
        }
        .glassEffect(Settings.shared.glassEffect)
        .frame(maxWidth: 50, maxHeight: 20)
    }
}
