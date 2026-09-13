//
//  Binding+Extension.swift
//  Astex
//
//  Created by Ben Herbert on 13/09/2026.
//
import SwiftUI

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0}
    )
}
