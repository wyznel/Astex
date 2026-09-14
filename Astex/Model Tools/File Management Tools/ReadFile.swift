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
            let path = input.path
            
            guard fileManager.fileExists(atPath: path) else {
                return ReadFileOutput(
                    success: false,
                    contents: "",
                    message: "The file does not exist at designated path: \(path)"
                )
            }
            
            let contents = try String(contentsOfFile: path, encoding: .utf8)
            print(contents)
            return ReadFileOutput(
                success: true,
                contents: contents,
                message: "Successful retrieval of file contents"
            )
        }
        return AnyTool(tool: tool, name: "read_file", capability: .readFile)
    }
}
