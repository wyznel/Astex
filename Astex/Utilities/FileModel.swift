//
//  FileModel.swift
//  Astex
//
//  Created by Ben Herbert on 09/08/2026.
//

public struct File: Codable, Sendable {
    public let name: String
    public let file_type: String
    public let size_in_megabytes: Int // Decimal MB, rounded down.
    public let isDirectory: Bool
}
