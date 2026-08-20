//
//  ToolPermission.swift
//  Astex
//
//  Created by Ben Herbert on 16/08/2026.
//

enum ToolPermission: String {
    case denied
    case askEveryTime
    case alwaysAllow
}

enum ToolCapability: String, CaseIterable {
    case readFiles, createFiles, writeFiles, deleteFiles, getTime
}
