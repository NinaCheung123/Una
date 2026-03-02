//
//  VoiceTag.swift
//  Una
//

import Foundation

enum VoiceTag: String, Codable, CaseIterable {
    case meeting
    case decision
    case feeling
    case random
    
    var displayName: String {
        switch self {
        case .meeting: return "会议"
        case .decision: return "决定"
        case .feeling: return "感受"
        case .random: return "随记"
        }
    }
    
    var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .decision: return "checkmark.circle.fill"
        case .feeling: return "heart.fill"
        case .random: return "sparkles"
        }
    }
}
