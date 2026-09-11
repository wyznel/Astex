//
//  MessageType.swift
//  Astex
//
//  Created by Ben Herbert on 11/09/2026.
//

nonisolated public enum MessageType: Codable, Equatable {
    case user
    case llm(LLMType)
}

nonisolated public enum LLMType: Codable {
    case thinking
    case response
    case tool
}
