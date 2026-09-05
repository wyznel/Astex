//
//  AllowedFileTypes.swift
//  Astex
//
//  Created by Ben Herbert on 04/09/2026.
//
import UniformTypeIdentifiers

public struct AllowedFileTypes {
    public let types: [UTType] = [.text, .pdf, .html, .rtf, .plainText, .css, .json, .javaScript, .pythonScript, .xml]
}
