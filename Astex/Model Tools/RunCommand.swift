////
////  RunCommand.swift
////  Astex
////
////  Created by Ben Herbert on 24/09/2026.
////
//
//import Foundation
//import Ollama
//
//struct RunCommandInput: Sendable {
//    let command: String
//}
//
//extension RunCommandInput: nonisolated Codable {}
//
//struct RunCommandOutput: Sendable {
//    let success: Bool
//    let result: String
//}
//
//extension RunCommandOutput: nonisolated Codable {}
//
//enum RunCommand {
//    
//    static func makeTool() -> AnyTool<RunCommandInput, RunCommandOutput> {
//        let tool = Tool<RunCommandInput, RunCommandOutput>(
//            name: "run_terminal_command",
//            description: """
//                Run a terminal command. INFORM USER THAT THEY ARE LIABLE FOR ANY COMMAND THAT IS RAN.
//                """
//        ) {
//            
//        }
//    }
//}
