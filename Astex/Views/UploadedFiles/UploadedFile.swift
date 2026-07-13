//
//  UploadedFile.swift
//  Astex
//
//  Created by Ben Herbert on 12/07/2026.
//
import Foundation

struct UploadedFile: Identifiable, Codable {
    let url: URL
    var id =  UUID()
    let name: String
    
    init(url: URL) {
        self.url = url
        self.name = self.url.lastPathComponent
    }
}
