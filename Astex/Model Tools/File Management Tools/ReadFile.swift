//
//  ReadFile.swift
//  Astex
//
//  Created by Ben Herbert on 13/09/2026.
//

import Foundation
import Darwin
import Ollama

struct ReadFileInput: Sendable {
    let path: String
}

extension ReadFileInput: nonisolated Codable {}

struct ReadFileOutput: Sendable {
    let success: Bool
    let contents: String
    let message: String
    var truncated: Bool = false
}

extension ReadFileOutput: nonisolated Codable {}

enum ReadFile {
    nonisolated static let maximumBytes = 64 * 1024
    nonisolated(unsafe) static let fileManager = FileManager.default
    
    static func makeTool() -> AnyTool<ReadFileInput, ReadFileOutput> {
        let tool = Tool<ReadFileInput, ReadFileOutput>(
            name: "read_file",
            description: "Reads up to 65536 bytes from a UTF-8 text file. The result states whether the contents are partial.",
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
                let descriptor = open(fileURL.path, O_RDONLY | O_NONBLOCK)
                guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
                let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
                defer { try? handle.close() }
                var info = stat()
                guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else {
                    return ReadFileOutput(success: false, contents: "", message: "The path is not a regular file.")
                }
                let data = try handle.read(upToCount: maximumBytes + 1) ?? Data()
                let truncated = data.count > maximumBytes
                var end = min(data.count, maximumBytes)
                // Keep complete UTF-8 characters at the output boundary.
                if truncated {
                    while end > maximumBytes - 3, data[end] & 0xC0 == 0x80 { end -= 1 }
                }
                let prefix = data.prefix(end)
                guard !prefix.contains(0), let contents = String(data: prefix, encoding: .utf8) else {
                    return ReadFileOutput(success: false, contents: "", message: "The file is not supported UTF-8 text.")
                }
                return ReadFileOutput(
                    success: true, contents: contents,
                    message: truncated ? "Partial result. The file exceeds the 65536-byte limit." : "The tool read the file.",
                    truncated: truncated
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
