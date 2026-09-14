//
//  ReadFile.swift
//  Astex
//
//  Created by Ben Herbert on 13/09/2026.
//

import Foundation
import Ollama

struct ReadFileInput: Sendable {
    let path: String
}

extension ReadFileInput: nonisolated Codable {}

struct ReadFileOutput: Sendable {
    let success: Bool
    let contents: String
    let message: String
}

extension ReadFileOutput: nonisolated Codable {}

enum ReadFile {
    nonisolated(unsafe) static let fileManager = FileManager.default
    
    static func makeTool() -> AnyTool<ReadFileInput, ReadFileOutput> {
        let tool = Tool<ReadFileInput, ReadFileOutput>(
            name: "read_file",
            description: "Returns the contents of a file",
            parameters: [
                "path": [
                    "type": "string",
                    "description": "An absolute path or a path relative to the home directory. Tilde paths are allowed."
                ]
            ],
            required: ["path"]
        ) { input in
            guard !input.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return ReadFileOutput(
                    success: false,
                    contents: "",
                    message: "The file path is empty."
                )
            }

            let fileURL = FileManager.resolveFile(from: input.path)
            var isDirectory: ObjCBool = false

            guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
                  !isDirectory.boolValue else {
                return ReadFileOutput(
                    success: false,
                    contents: "",
                    message: "No file exists at this path: \(fileURL.path)"
                )
            }

            do {
                let contents = try String(contentsOf: fileURL, encoding: .utf8)
                return ReadFileOutput(
                    success: true,
                    contents: contents,
                    message: "The tool read the file at \(fileURL.path)."
                )
            } catch {
                return ReadFileOutput(
                    success: false,
                    contents: "",
                    message: "The tool could not read the file at \(fileURL.path): \(error.localizedDescription)"
                )
            }
        }
        return AnyTool(tool: tool, name: "read_file", capability: .readFile)
    }
}
