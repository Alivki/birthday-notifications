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

// MARK: - Theme

enum Theme {
    /// Lightened from #2443F8 — reads friendlier, less Apple-blue.
    static let brand = Color(hex: "6680FF")
    static let brandDeep = Color(hex: "3E5BD9")
    static let brandSoft = Color(hex: "EEF1FF")
    static let brandWash = Color(hex: "F4F6FF")

    /// Warm offwhite for the app background — feels friendlier than gray.
    static let surface = Color(hex: "FAFAF6")
    static let card = Color(hex: "FFFFFF")

    static let celebration = Color(hex: "FF7B7B")
    static let celebrationSoft = Color(hex: "FFEDED")

    static let warm = Color(hex: "FFB547")

    static let textSecondary = Color(hex: "7A7A85")

    static let cardCorner: CGFloat = 18
    static let heroCorner: CGFloat = 24

    static let cardShadow = ShadowStyle(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func cardShadow() -> some View {
        shadow(color: Theme.cardShadow.color, radius: Theme.cardShadow.radius, x: Theme.cardShadow.x, y: Theme.cardShadow.y)
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
    ("Blue",   "6680FF"),
    ("Indigo", "8B7BFF"),
    ("Plum",   "B57AFF"),
    ("Coral",  "FF7B7B"),
    ("Peach",  "FF9F6E"),
    ("Amber",  "FFB547"),
    ("Sage",   "5DBF93"),
    ("Teal",   "47B5C5"),
    ("Slate",  "7A8AA0"),
    ("Rose",   "E68FA6"),
]
