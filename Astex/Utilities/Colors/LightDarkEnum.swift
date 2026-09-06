//
//  LightDarkEnum.swift
//  Astex
//
//  Created by Ben Herbert on 06/09/2026.
//
import Foundation

public enum AppearanceOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .system:
            return "display"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
}
