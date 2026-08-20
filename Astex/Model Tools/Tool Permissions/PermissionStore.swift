//
//  PermissionStore.swift
//  Astex
//
//  Created by Ben Herbert on 16/08/2026.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class PermissionStore: ObservableObject {
    static let shared = PermissionStore()
    enum UserChoice {
        case allowOnce,
             allowForChat,
             alwaysAllow,
             denyOnce,
             alwaysDeny
    }
    
    struct PermissionRequest: Identifiable {
        let id = UUID()
        let toolName: String
        let modelName: String
        let capability: ToolCapability
        let summary: String
        let sessionID: ObjectIdentifier?
    }
    
    @Published var pendingRequest: PermissionRequest?
    @Published private(set) var permissions: [ToolCapability: ToolPermission] = [:]
    
    init() {
        for cap in ToolCapability.allCases {
            permissions[cap] = readStoredPermission(for: cap)
        }
    }
    
    private let defaults = UserDefaults.standard
    
    var currentSessionID: ObjectIdentifier?
    private var sessionGrants: [ObjectIdentifier: Set<ToolCapability>] = [:]
    
    private var continuation: CheckedContinuation<Bool, Never>?
    
    private func readStoredPermission(for cap: ToolCapability) -> ToolPermission {
        return defaults.string(forKey: Self.key(for: cap))
            .flatMap(ToolPermission.init(rawValue:)) ?? .askEveryTime
    }
    
    func permission(for cap: ToolCapability) -> ToolPermission {
        return permissions[cap] ?? .askEveryTime
    }
    
    func set(_ permission: ToolPermission, for cap: ToolCapability) {
        defaults.set(permission.rawValue, forKey: Self.key(for: cap))
        permissions[cap] = permission
    }
    
    func requestPermission(tool: String, capability: ToolCapability, summary: String) async -> Bool {
    
        if let sessionID = currentSessionID, sessionGrants[sessionID]?.contains(capability) == true {
            return true
        }
        
        switch permission(for: capability) {
        case .alwaysAllow: return true
        case .denied: return false
        case .askEveryTime:
            
            if Task.isCancelled { return false}
            
            let modelName = Settings.shared.selectedEngine == .ollama ? Settings.shared.selectedModel : Settings.shared.rapidMLXSelectedModel
            
            return await withTaskCancellationHandler {
                await withCheckedContinuation { cont in
                    continuation = cont
                    pendingRequest = PermissionRequest(
                        toolName: tool,
                        modelName: modelName,
                        capability: capability,
                        summary: summary,
                        sessionID: currentSessionID
                    )
                }
            } onCancel: {
                Task { @MainActor in
                    PermissionStore.shared.cancelPending()
                }
            }
        }
    }
    
    func cancelPending() {
        guard let cont = continuation else { return }
        continuation = nil
        pendingRequest = nil
        cont.resume(returning: false)
    }
    
    func resolve(_ choice: UserChoice) {
        guard let cont = continuation, let req = pendingRequest else { return }
        continuation = nil
        pendingRequest = nil
        switch choice {
        case .allowOnce:
            cont.resume(returning: true)
        case .allowForChat:
            if let sessionID = req.sessionID {
                sessionGrants[sessionID, default: []].insert(req.capability)
            }
            cont.resume(returning: true)
        case .alwaysAllow:
            set(.alwaysAllow, for: req.capability)
            cont.resume(returning: true)
        case .denyOnce:
            cont.resume(returning: false)
        case .alwaysDeny:
            set(.denied, for: req.capability)
            cont.resume(returning: false)
        }
    }
 
    private static func key(for cap: ToolCapability) -> String {
        return "perm.\(cap.rawValue)"
    }
}
