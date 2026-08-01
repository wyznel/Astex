//
//  FileHandling.swift
//  Astex
//
//  Created by Ben Herbert on 12/07/2026.
//
import Foundation

enum FileHandling {
    
    /// Reads the text contents of an UploadedFile.
    /// Returns nil if the file cannot be read.
    static func readContents(of file: UploadedFile) -> String? {
        do {
            let contents = try String(contentsOf: file.url, encoding: .utf8)
            return contents
        } catch {
            print("Error reading file \(file.name): \(error)")
            return nil
        }
    }

    /// Builds a context string from an array of uploaded files.
    /// Each file's contents are wrapped with its filename for clarity.
    static func buildContext(from files: [UploadedFile]) -> String? {
        var sections: [String] = []
        for file in files {
            guard let contents = readContents(of: file) else { continue }
            sections.append("--- File: \(file.name) ---\n\(contents)\n--- End: \(file.name) ---")
        }
        guard !sections.isEmpty else { return nil }
        return sections.joined(separator: "\n\n")
    }
}
