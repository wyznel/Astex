//
//  ListDirectory.swift
//  Astex
//
//  Created by Ben Herbert on 09/08/2026.
//

import Foundation
import Ollama

struct ListDirectoryInput: Sendable {
    let path: String
}

extension ListDirectoryInput: nonisolated Codable {}

struct ListDirectoryOutput: Sendable {
    let success: Bool
    let path: String
    let items: [File]
    let message: String
}

extension ListDirectoryOutput: nonisolated Codable {}

enum ListDirectory {
    nonisolated(unsafe) static let fileManager = FileManager.default

    static func makeTool() -> AnyTool<ListDirectoryInput, ListDirectoryOutput> {
        let tool = Tool<ListDirectoryInput, ListDirectoryOutput>(
            name: "list_files_in_directory",
            description: """
                Lists the immediate contents of a directory. The tool does not list the contents of subdirectories. File sizes use decimal megabytes (MB).
                """,
            parameters: [
                "path": [
                    "type": "string",
                    "description": "An absolute path or a path relative to the home directory. Tilde paths are allowed."
                ]
            ],
            required: ["path"]
        ) { input in
            guard !input.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return ListDirectoryOutput(
                    success: false,
                    path: "",
                    items: [],
                    message: "The directory path is empty."
                )
            }

            let directory = FileManager.resolveDirectory(from: input.path)

            do {
                let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey]
                let contents = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: Array(keys),
                    options: []
                )

                let items = try contents.map { url in
                    let values = try url.resourceValues(forKeys: keys)
                    let isDirectory = values.isDirectory ?? false
                    let fileType: String

                    if isDirectory {
                        fileType = "directory"
                    } else if url.pathExtension.isEmpty {
                        fileType = "file"
                    } else {
                        fileType = url.pathExtension.lowercased()
                    }

                    let byteCount = isDirectory ? 0 : values.fileSize ?? 0
                    return File(
                        name: url.lastPathComponent,
                        file_type: fileType,
                        size_in_megabytes: byteCount / 1_000_000,
                        isDirectory: isDirectory
                    )
                }
                .sorted { first, second in
                    if first.isDirectory != second.isDirectory {
                        return first.isDirectory
                    }
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }

                return ListDirectoryOutput(
                    success: true,
                    path: directory.path,
                    items: items,
                    message: "Found \(items.count) items."
                )
            } catch {
                return ListDirectoryOutput(
                    success: false,
                    path: directory.path,
                    items: [],
                    message: "Failed to list the directory: \(error.localizedDescription)"
                )
            }
        }

        return AnyTool(tool: tool, name: "list_files_in_directory", capability: .listDirectory)
    }
}
