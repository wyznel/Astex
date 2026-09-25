//
//  ListDirectory.swift
//  Astex
//
//  Created by Ben Herbert on 09/08/2026.
//

import Foundation
import Darwin
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
    var truncated: Bool = false
}

extension ListDirectoryOutput: nonisolated Codable {}

enum ListDirectory {
    nonisolated static let maximumItems = 500

    static func makeTool() -> AnyTool<ListDirectoryInput, ListDirectoryOutput> {
        let tool = Tool<ListDirectoryInput, ListDirectoryOutput>(
            name: "list_files_in_directory",
            description: """
                Lists up to 500 immediate directory entries. The result states whether the list is partial. File sizes use decimal megabytes (MB).
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
                guard let stream = opendir(directory.path) else {
                    throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
                }
                defer { closedir(stream) }
                var items: [File] = []
                var truncated = false
                while true {
                    errno = 0
                    guard let entry = readdir(stream) else {
                        if errno != 0 { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
                        break
                    }
                    let name = withUnsafePointer(to: &entry.pointee.d_name) {
                        $0.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen) + 1) {
                            String(cString: $0)
                        }
                    }
                    if name == "." || name == ".." { continue }
                    guard items.count < maximumItems else {
                        truncated = true
                        break
                    }
                    let url = directory.appendingPathComponent(name)
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
                    items.append(File(
                        name: url.lastPathComponent,
                        file_type: fileType,
                        size_in_megabytes: byteCount / 1_000_000,
                        isDirectory: isDirectory
                    ))
                }
                items.sort { first, second in
                    if first.isDirectory != second.isDirectory {
                        return first.isDirectory
                    }
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }

                return ListDirectoryOutput(
                    success: true,
                    path: directory.path,
                    items: items,
                    message: truncated ? "Partial result. The directory exceeds the 500-item limit." : "Found \(items.count) items.",
                    truncated: truncated
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
