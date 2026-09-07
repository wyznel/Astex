//
//  ColourThemesEnum.swift
//  Astex
//
//  Created by Ben Herbert on 06/09/2026.
//

public enum ColourThemes: String, CaseIterable, Identifiable {
    case arctic
    case sepia
    case sage
    case nord
    
    public var id: String { theme.raw }
    
    var theme: any CustomTheme {
        switch self {
        case .arctic:
            ArcticTheme()
        case .sepia:
            SepiaTheme()
        case .sage:
            SageTheme()
        case .nord:
            NordTheme()
        }

    }
}
