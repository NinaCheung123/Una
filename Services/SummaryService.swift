//
//  SummaryService.swift
//  Una
//
//  Auto-tag, structured summary + insights. Local (Apple Intelligence style when available).
//

import Foundation

final class SummaryService {
    static let shared = SummaryService()
    
    private let unaPrompt = "你是温暖小怪兽 Una，用温柔语气把这段整理成结构化日记：raw transcript + bullet summary + 2-3 light insights"
    
    private init() {}
    
    func autoTag(transcript: String) -> VoiceTag {
        let t = transcript.lowercased()
        if t.contains("会议") || t.contains("开会") || t.contains("讨论") || t.contains("汇报") {
            return .meeting
        }
        if t.contains("决定") || t.contains("选择") || t.contains("要不要") || t.contains("应该") {
            return .decision
        }
        if t.contains("感觉") || t.contains("心情") || t.contains("开心") || t.contains("累") || t.contains("难过") || t.contains("焦虑") || t.contains("放松") {
            return .feeling
        }
        return .random
    }
    
    func summarize(transcript: String) -> (summary: String, insights: [String]) {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ("（暂无内容）", [])
        }
        var summary = "📔 今日随记\n\n"
        summary += "**原文**\n\(transcript)\n\n"
        summary += "**Una 的小结**\n"
        let lines = transcript.split(separator: "\n").map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines.prefix(5) {
            summary += "• \(line.trimmingCharacters(in: .whitespaces))\n"
        }
        summary += "\n✨ 慢慢来，今天也有在好好记录哦～"
        
        var insights: [String] = []
        if lines.count >= 2 {
            insights.append("今天记下了好几件小事，都在心里了～")
        }
        if transcript.contains("累") || transcript.contains("忙") {
            insights.append("记得休息一下，Una 陪着你。")
        }
        insights.append("每一个当下都值得被看见。")
        return (summary, Array(insights.prefix(3)))
    }
    
    func generateDiscoveryReasons(for sparkText: String) -> [String] {
        let templates = [
            "睡眠不足", "任务太多", "天气影响", "情绪波动", "运动不够",
            "社交消耗", "期待过高", "节奏太快", "边界不清", "比较心理"
        ]
        return Array(templates.prefix(8))
    }
    
    /// 4–6 gentle, non-judgmental reasons (for "想探索其他可能的原因吗？").
    func suggestInitialReasons(for sparkText: String) -> [String] {
        let gentle = [
            "可能想给自己一点空间",
            "也许在保护自己不被消耗",
            "或许需要更多休息",
            "说不定是身体在提醒你",
            "可能是节奏需要调整",
            "也许在等待什么"
        ]
        return Array(gentle.shuffled().prefix(5))
    }
    
    /// 3 new suggestions (for "Quick add more options"), excluding existing.
    func suggestQuickReasons(for sparkText: String, existing: [String]) -> [String] {
        let pool = [
            "睡眠不足", "任务太多", "天气影响", "情绪波动", "运动不够",
            "社交消耗", "期待过高", "节奏太快", "边界不清", "比较心理",
            "可能想给自己一点空间", "也许在保护自己", "或许需要休息"
        ]
        let set = Set(existing)
        return pool.filter { !set.contains($0) }.shuffled().prefix(3).map { $0 }
    }
    
    /// Gentle reframing for a single reason.
    func reframing(for reason: String) -> String {
        let reframings: [String: String] = [
            "睡眠不足": "好好睡一觉，明天会更好～",
            "任务太多": "任务多说明你在被需要，慢慢来～",
            "情绪波动": "情绪来了又走，都是正常的～",
            "期待过高": "期待是好事，放过自己也是～",
            "节奏太快": "慢下来，Una 陪着你～",
            "比较心理": "你只需要跟自己比～"
        ]
        return reframings[reason] ?? "你已经在觉察了，这本身就是进步～"
    }
    
    func refineToTopReasons(crossedOut: Set<Int>, allReasons: [String]) -> (top: [String], reframing: String) {
        let remaining = allReasons.enumerated().filter { !crossedOut.contains($0.offset) }.map(\.element)
        let top = Array(remaining.prefix(3))
        let reframing = "累是因为你在认真生活呀～ Una 觉得你已经做得很好了 🐾"
        return (top, reframing)
    }
}
