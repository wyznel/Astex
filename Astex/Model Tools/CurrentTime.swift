//
//  CurrentTime.swift
//  Astex
//
//  Created by Ben Herbert on 27/07/2026.
//

import Foundation
import Ollama

struct CurrentTimeInput: Sendable {}
extension CurrentTimeInput: nonisolated Codable {}

struct CurrentTimeOutput: Sendable {
    let time: String
}
extension CurrentTimeOutput: nonisolated Codable {}

enum CurrentTime {
    
    static func makeTool() -> AnyTool<CurrentTimeInput, CurrentTimeOutput> {
        let tool = Tool<CurrentTimeInput, CurrentTimeOutput>(
            name: "get_current_time",
            description: "Gets the current time",
            parameters: [:],
            required: []
        ) { input in
           //Get current time in yyyy-MM-dd HH:mm:ss
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone.current
            return CurrentTimeOutput(time: formatter.string(from: now))
        }
        
        return AnyTool(tool: tool, name: "get_current_time")
    }
}
