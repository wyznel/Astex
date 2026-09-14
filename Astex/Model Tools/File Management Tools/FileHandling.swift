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

extension FileManager {
    /// Resolves a file URL from a model-provided path.
    ///
    /// - Tilde (`~`) is expanded to the home directory.
    /// - Relative paths are resolved against the home directory.
    nonisolated static func resolveFile(from rawPath: String) -> URL {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let expandedPath = (trimmedPath as NSString).expandingTildeInPath

        if expandedPath.hasPrefix("/") {
            return URL(fileURLWithPath: expandedPath).standardizedFileURL
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(expandedPath)
            .standardizedFileURL
    }

    /// Resolves a full directory URL from a model-provided path.
    ///
    /// - Tilde (`~`) is expanded to the home directory.
    /// - Relative paths are resolved against the home directory.
    /// - An empty path uses `fallbackDirectory`, or the home directory if no fallback exists.
    /// - If `filename` exists and the path ends in a file-like component, the function removes that component.
    nonisolated static func resolveDirectory(
        from rawPath: String,
        filename: String? = nil,
        fallbackDirectory: URL? = nil
    ) -> URL {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPath.isEmpty else {
            return fallbackDirectory ?? FileManager.default.homeDirectoryForCurrentUser
        }

        let expanded = (trimmedPath as NSString).expandingTildeInPath
        var directory: URL
        if expanded.hasPrefix("/") {
            directory = URL(fileURLWithPath: expanded, isDirectory: true)
        } else {
            directory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(expanded, isDirectory: true)
        }

        if let filename {
            let lastComponent = directory.lastPathComponent
            if lastComponent.caseInsensitiveCompare(filename) == .orderedSame
                || looksLikeFilePath(lastComponent) {
                directory.deleteLastPathComponent()
            }
        }

        return directory
    }

    /// Returns true when a path component has a file extension.
    private nonisolated static func looksLikeFilePath(_ component: String) -> Bool {
        let nsComponent = component as NSString
        let dot = nsComponent.range(of: ".")
        return dot.location > 0 && dot.location < nsComponent.length - 1
    }
}
