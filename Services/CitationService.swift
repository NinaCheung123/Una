//
//  CitationService.swift
//  Una
//
//  Parse voice commands: "remind me last Tuesday grocery" / "link this to coupon anxiety".
//  On-device search + date filter → pull spark, create SparkLink.
//

import Foundation

struct CitationService {
    static let shared = CitationService()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans")
        f.dateStyle = .short
        return f
    }()
    
    private init() {}
    
    /// e.g. "提醒我上周二超市那个" / "关联到优惠券焦虑"
    struct ParsedCommand {
        let keyword: String
        let dateHint: Date?
        let linkTo: Bool
    }
    
    func parseCommand(from transcript: String) -> ParsedCommand? {
        let t = transcript.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return nil }
        
        // "关联到 XXX" / "链接到 XXX"
        if t.contains("关联到") || t.contains("链接到") {
            let parts = t.split(separator: "到", maxSplits: 1)
            let keyword = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : t
            if !keyword.isEmpty { return ParsedCommand(keyword: keyword, dateHint: nil, linkTo: true) }
        }
        
        // "提醒我 [date] XXX"
        if t.contains("提醒我") {
            var keyword = t
            if let range = t.range(of: "提醒我") {
                keyword = String(t[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
            let dateHint = parseRelativeDate(from: t)
            return ParsedCommand(keyword: keyword, dateHint: dateHint, linkTo: false)
        }
        
        return nil
    }
    
    private func parseRelativeDate(from text: String) -> Date? {
        let cal = Calendar.current
        var comp = cal.dateComponents([.year, .month, .day], from: Date())
        if text.contains("昨天") {
            comp.day = (comp.day ?? 1) - 1
            return cal.date(from: comp)
        }
        if text.contains("前天") {
            comp.day = (comp.day ?? 1) - 2
            return cal.date(from: comp)
        }
        if text.contains("上周") || text.contains("上週") {
            comp.day = (comp.day ?? 1) - 7
            return cal.date(from: comp)
        }
        if text.contains("上周一") || text.contains("上星期一") { comp.day = (comp.day ?? 1) - 7; comp.weekday = 2; return cal.date(from: comp) }
        if text.contains("上周二") || text.contains("上星期二") { comp.day = (comp.day ?? 1) - 6; comp.weekday = 3; return cal.date(from: comp) }
        if text.contains("上周三") || text.contains("上星期三") { comp.day = (comp.day ?? 1) - 5; return cal.date(from: comp) }
        if text.contains("上周四") || text.contains("上星期四") { comp.day = (comp.day ?? 1) - 4; return cal.date(from: comp) }
        if text.contains("上周五") || text.contains("上星期五") { comp.day = (comp.day ?? 1) - 3; return cal.date(from: comp) }
        return nil
    }
    
    func searchSparks(keyword: String, nearDate: Date?, in sparks: [Spark]) -> [Spark] {
        let lower = keyword.lowercased()
        var filtered = sparks.filter { $0.text.localizedCaseInsensitiveContains(lower) || $0.text.contains(keyword) }
        if let date = nearDate {
            let dayStart = Calendar.current.startOfDay(for: date)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            filtered = filtered.filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }
        }
        if filtered.isEmpty, nearDate == nil {
            filtered = sparks.filter { $0.text.localizedCaseInsensitiveContains(lower) || $0.text.contains(keyword) }
        }
        return filtered
    }
}
