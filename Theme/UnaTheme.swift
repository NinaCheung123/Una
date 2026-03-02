//
//  UnaTheme.swift
//  Una
//

import SwiftUI

enum UnaTheme {
    static let primary = Color(hex: "D8B4FE")
    static let accent = Color(hex: "E0BBE4")
    static let background = Color(hex: "FDF8FF")
    static let surface = Color(hex: "F5EDFF")
    static let text = Color(hex: "2D1B4E")
    static let textSecondary = Color(hex: "5C4A6E")
    
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.9), accent.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var softGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.4), accent.opacity(0.3), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.95), surface.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static let defaultEncouragements = [
        "你今天已经很棒啦～",
        "慢慢来，Una 陪着你～",
        "每一个小进步都算数 ✨",
        "休息一下也没关系呀 🐾",
        "你值得被温柔对待～",
        "今天也有在好好记录哦 🐾"
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
