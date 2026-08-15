////
////  ListDirectory.swift
////  Astex
////
////  Created by Ben Herbert on 09/08/2026.
////
//
//import Foundation
//import Ollama
//
//struct ListDirectoryInput: Sendable {
//    let path: String
//}
//
//extension ListDirectoryInput: nonisolated Codable {}
//
//struct ListDirectoryOutput: Sendable {
//    let items: [File]
//    
//}
//
//extension ListDirectoryOutput: nonisolated Codable {}
//
//enum ListDirectory {
//    
//    static func makeTool() -> AnyTool<ListDirectoryInput, ListDirectoryOutput> {
//        
//    }
//    
//}
