//
//  UploadedFileView.swift
//  Astex
//
//  Created by Ben Herbert on 12/07/2026.
//
import SwiftUI

struct UploadedFileView: View {
    let file: UploadedFile
    @Binding var uploadedFiles: [UploadedFile]
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.document")
                .padding(2)
            Text(file.url.lastPathComponent)
            Button {
                withAni {
                    file.url.stopAccessingSecurityScopedResource()
                    uploadedFiles.removeAll { $0.id == file.id }
                }
            }label: {
                Image(systemName: "delete.left")
            }
            .contentShape(Rectangle())
        }
        .frame(maxWidth: 100, maxHeight: 30)
        .glassEffect(Settings.shared.glassEffect, in: .rect(cornerRadius: 6))
        .offset(y: 4)
    }
}
