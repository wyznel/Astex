//
//  StreamChunk.swift
//  Astex
//
//  Created by Ben Herbert on 19/07/2026.
//

public enum StreamChunk {
    case thinking(String)
    case content(String)
    case toolCall(String)
    case loading(Bool)
}
