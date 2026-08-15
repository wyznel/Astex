//
//  FileModel.swift
//  Astex
//
//  Created by Ben Herbert on 09/08/2026.
//

public struct File: Codable {
    public let name: String
    public let file_type: String
    public let size: Int //Will default to MB
    public let isDirectory: Bool
}
