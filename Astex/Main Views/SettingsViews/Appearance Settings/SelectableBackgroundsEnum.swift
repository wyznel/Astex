//
//  SelectableBackgroundsEnum.swift
//  Astex
//
//  Created by Ben Herbert on 07/09/2026.
//

public enum Backgrounds: String, CaseIterable, Identifiable {
    case sepia = "Sepia"
    case sage = "Sage"
    case none = "None"
    
    public var id: String { bg.name }
    
    var bg: BackgroundChoice {
        switch self {
        case .sepia:
            return BackgroundChoice(name: "Sepia", fileName: "sepia-bg")
        case .sage:
            return BackgroundChoice(name: "Sage", fileName: "sage-bg")
        case .none:
            return BackgroundChoice(name: "None", fileName: "")
        }
    }
    
}

struct BackgroundChoice {
    let name: String
    let fileName: String
}
