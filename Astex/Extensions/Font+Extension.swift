//
//  Font+Extension.swift
//  Astex
//
//  Created by Ben Herbert on 31/07/2026.
//

import SwiftUI

extension Font {
    static func alanSans(_ size: CGFloat, relativeTo textStyle: TextStyle = .body) -> Font {
        .custom("Alan Sans", size: size, relativeTo: textStyle)
    }
}
