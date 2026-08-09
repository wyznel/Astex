//
//  DocumentCreation.swift
//  Astex
//
//  Created by Ben Herbert on 13/07/2026.
//
import Ollama
import Foundation

// MARK: - Document Creation Tool

struct DocumentCreationInput: Sendable {
    let path: String?
    let filename: String
    let content: String
}

extension DocumentCreationInput: nonisolated Codable {}

struct DocumentCreationOutput: Sendable {
    let success: Bool
    let path: String
    let message: String
}

extension DocumentCreationOutput: nonisolated Codable {}

enum DocumentCreation {

    /// Default directory for LLM-created documents.
    nonisolated(unsafe) static var outputDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads", isDirectory: true)
            .appendingPathComponent("Astex", isDirectory: true)
    }

    /// Returns true when a path component looks like a file (has a dot extension,
    /// e.g. `report.md`) rather than a directory name (e.g. `reports` or `.config`).
    private static func looksLikeFilePath(_ component: String) -> Bool {
        let nsComponent = component as NSString
        let dot = nsComponent.range(of: ".")
        return dot.location > 0 && dot.location < nsComponent.length - 1
    }

    /// Resolves the directory a document should be saved into from the model-provided path.
    ///
    /// - Tilde (`~`) is expanded to the home directory.
    /// - Relative paths are resolved against the home directory.
    /// - An empty path falls back to `~/Downloads/Astex/`.
    /// - If the path actually includes the filename (e.g. `~/Desktop/report.md`), that
    ///   component is dropped so the file isn't written into a folder named `report.md`.
    static func resolveDirectory(from rawPath: String, filename: String) -> URL {
        let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPath.isEmpty else {
            return outputDirectory
        }

        let expanded = (trimmedPath as NSString).expandingTildeInPath
        var directory: URL
        if expanded.hasPrefix("/") {
            directory = URL(fileURLWithPath: expanded, isDirectory: true)
        } else {
            directory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(expanded, isDirectory: true)
        }

        if directory.lastPathComponent.lowercased() == filename.lowercased()
            || looksLikeFilePath(directory.lastPathComponent) {
            directory.deleteLastPathComponent()
        }

        return directory
    }

    /// Builds and returns the Ollama Tool wrapped in an AnyTool for registry registration.
    static func makeTool() -> AnyTool<DocumentCreationInput, DocumentCreationOutput> {
        let tool = Tool<DocumentCreationInput, DocumentCreationOutput>(
            name: "create_document",
            description: "Creates and saves a text document to disk. Use this when the user asks you to write, generate, or save a document, note, file, or report. ENSURE TO INFORM THE USER OF THE SAVED LOCATION AND CONTENTS OF THE FILE",
            parameters: [
                "path": [
                    "type": "string",
                    "description": "The directory to save the document to. Can be an absolute path or a path relative to the home directory, e.g. ~/Downloads/Astex/. If the user does not provide a path, use the default path of: ~/Downloads/Astex/"
                ],
                "filename": [
                    "type": "string",
                    "description": "The filename including extension. Must not contain path separators."
                ],
                "content": [
                    "type": "string",
                    "description": "The full text content of the document to save."
                ]
            ],
            required: ["filename", "content"]
        ) { input in
            // Sanitise filename to prevent path traversal
            let sanitised = input.filename
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: "\\", with: "-")
                .replacingOccurrences(of: "..", with: "")

            guard !sanitised.isEmpty else {
                return DocumentCreationOutput(success: false, path: "", message: "Invalid filename.")
            }

            do {
                let directory = await resolveDirectory(from: input.path ?? "", filename: sanitised)
                let fileURL = directory.appendingPathComponent(sanitised)

                
                // directory, even after standardisation (e.g. resolving any "..").
                let directoryPath = directory.standardizedFileURL.path
                guard fileURL.standardizedFileURL.path.hasPrefix(directoryPath + "/") else {
                    return DocumentCreationOutput(success: false, path: "", message: "Invalid file path.")
                }

                // Create the target directory (and any missing parents)
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true
                )

                // dont to overwrite existing files :D
                guard !FileManager.default.fileExists(atPath: fileURL.path) else {
                    return DocumentCreationOutput(
                        success: false,
                        path: fileURL.path,
                        message: "File '\(sanitised)' already exists."
                    )
                }

                try input.content.write(to: fileURL, atomically: true, encoding: .utf8)

                return DocumentCreationOutput(
                    success: true,
                    path: fileURL.path,
                    message: "Document saved to \(fileURL.path)"
                )
            } catch {
                return DocumentCreationOutput(
                    success: false,
                    path: "",
                    message: "Failed to save document: \(error.localizedDescription)"
                )
            }
        }
        return AnyTool(tool: tool, name: "create_document")
    }
}
