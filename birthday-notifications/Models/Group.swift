//
//  Group.swift
//  final-birthday-notifications
//
//  Created by Iver Lindholm on 01/03/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class PersonGroup {
    var name: String
    var colorHex: String
    var members: [Person]
    var createdAt: Date

    var color: Color {
        Color(hex: colorHex)
    }

    init(
        name: String,
        colorHex: String = "007AFF",
        members: [Person] = []
    ) {
        self.name = name
        self.colorHex = colorHex
        self.members = members
        self.createdAt = .now
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0.48; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

let groupColorOptions: [(name: String, hex: String)] = [
    ("Blue", "007AFF"),
    ("Red", "FF3B30"),
    ("Green", "34C759"),
    ("Orange", "FF9500"),
    ("Purple", "AF52DE"),
    ("Pink", "FF2D55"),
    ("Teal", "5AC8FA"),
    ("Yellow", "FFCC00"),
    ("Indigo", "5856D6"),
    ("Mint", "00C7BE"),
]
