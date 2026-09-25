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
        let id: UUID
        let toolName: String
        let modelName: String
        let capability: ToolCapability
        let summary: String
        let sessionID: ObjectIdentifier?
    }
    
    @Published private(set) var pendingRequest: PermissionRequest?
    @Published private(set) var permissions: [ToolCapability: ToolPermission] = [:]
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for cap in ToolCapability.allCases {
            permissions[cap] = readStoredPermission(for: cap)
        }
    }
    
    private let defaults: UserDefaults
    
    var currentSessionID: ObjectIdentifier?
    private var sessionGrants: [ObjectIdentifier: Set<ToolCapability>] = [:]
    
    private struct QueuedRequest {
        let request: PermissionRequest
        let continuation: CheckedContinuation<Bool, Never>
    }

    private var queue: [QueuedRequest] = []
    
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
    
    private func decision(for capability: ToolCapability, sessionID: ObjectIdentifier?) -> Bool? {
        switch permission(for: capability) {
        case .alwaysAllow: return true
        case .denied: return false
        case .askEveryTime:
            if let sessionID, sessionGrants[sessionID]?.contains(capability) == true { return true }
            return nil
        }
    }

    func requestPermission(tool: String, capability: ToolCapability, summary: String) async -> Bool {
        guard !Task.isCancelled else { return false }
        let sessionID = currentSessionID
        if let decision = decision(for: capability, sessionID: sessionID) { return decision }
        let request = PermissionRequest(
            id: UUID(), toolName: tool,
            modelName: Settings.shared.selectedEngine == .ollama
                ? Settings.shared.selectedModel : Settings.shared.rapidMLXSelectedModel,
            capability: capability, summary: summary, sessionID: sessionID
        )
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(returning: false)
                    return
                }
                queue.append(QueuedRequest(request: request, continuation: continuation))
                presentNext()
            }
        } onCancel: {
            Task { @MainActor in self.cancel(requestID: request.id) }
        }
    }

    private func presentNext() {
        while let first = queue.first {
            if let decision = decision(for: first.request.capability, sessionID: first.request.sessionID) {
                queue.removeFirst().continuation.resume(returning: decision)
            } else {
                pendingRequest = first.request
                return
            }
        }
        pendingRequest = nil
    }

    private func cancel(requestID: UUID) {
        guard let index = queue.firstIndex(where: { $0.request.id == requestID }) else { return }
        queue.remove(at: index).continuation.resume(returning: false)
        presentNext()
    }

    func cancelPending() {
        let cancelled = queue
        queue.removeAll()
        pendingRequest = nil
        for item in cancelled { item.continuation.resume(returning: false) }
    }

    func resolve(_ choice: UserChoice, requestID: UUID) {
        guard let first = queue.first, first.request.id == requestID else { return }
        queue.removeFirst()
        pendingRequest = nil
        let req = first.request
        let allowed: Bool
        switch choice {
        case .allowOnce:
            allowed = true
        case .allowForChat:
            if let sessionID = req.sessionID {
                sessionGrants[sessionID, default: []].insert(req.capability)
            }
            allowed = true
        case .alwaysAllow:
            set(.alwaysAllow, for: req.capability)
            allowed = true
        case .denyOnce:
            allowed = false
        case .alwaysDeny:
            set(.denied, for: req.capability)
            allowed = false
        }
        first.continuation.resume(returning: allowed)
        presentNext()
    }

    private static func key(for cap: ToolCapability) -> String {
        return "perm.\(cap.rawValue)"
    }
}
