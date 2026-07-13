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

    /// Base directory for all LLM-created documents.
    nonisolated(unsafe) static var outputDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("/Documents/Astex/", isDirectory: true)
    }

    /// Builds and returns the Ollama Tool wrapped in an AnyTool for registry registration.
    static func makeTool() -> AnyTool<DocumentCreationInput, DocumentCreationOutput> {
        let tool = Tool<DocumentCreationInput, DocumentCreationOutput>(
            name: "create_document",
            description: "Creates and saves a text document to disk. Use this when the user asks you to write, generate, or save a document, note, file, or report.",
            parameters: [
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

            let directory = outputDirectory
            let fileURL = directory.appendingPathComponent(sanitised)

            // Verify the resolved path stays within the output directory
            let resolvedPath = fileURL.standardizedFileURL.path
            let directoryPath = directory.standardizedFileURL.path
            guard resolvedPath.hasPrefix(directoryPath) else {
                return DocumentCreationOutput(success: false, path: "", message: "Invalid file path.")
            }

            do {
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true
                )

                // Refuse to overwrite existing files
                guard !FileManager.default.fileExists(atPath: fileURL.path) else {
                    return DocumentCreationOutput(
                        success: false,
                        path: fileURL.path,
                        message: "File '\(sanitised)' already exists."
                    )
                }

                // Atomic write prevents partial file creation on failure
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

