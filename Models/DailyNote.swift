//
//  DailyNote.swift
//  Una
//

import Foundation

struct DailyNote: Identifiable, Codable {
    var id: UUID
    var date: Date
    var rawVoiceText: String
    var rawTranscripts: [String]
    var summary: String
    var insights: [String]
    var tags: [String]
    var linkedSparkIds: [UUID]
    var voiceEntryIds: [UUID]
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date,
        rawVoiceText: String = "",
        rawTranscripts: [String] = [],
        summary: String,
        insights: [String] = [],
        tags: [String] = [],
        linkedSparkIds: [UUID] = [],
        voiceEntryIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.rawVoiceText = rawVoiceText
        self.rawTranscripts = rawTranscripts
        self.summary = summary
        self.insights = insights
        self.tags = tags
        self.linkedSparkIds = linkedSparkIds
        self.voiceEntryIds = voiceEntryIds
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, rawVoiceText, rawTranscripts, summary, insights, tags, linkedSparkIds, voiceEntryIds, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        rawVoiceText = try c.decodeIfPresent(String.self, forKey: .rawVoiceText) ?? ""
        rawTranscripts = try c.decodeIfPresent([String].self, forKey: .rawTranscripts) ?? []
        summary = try c.decode(String.self, forKey: .summary)
        insights = try c.decodeIfPresent([String].self, forKey: .insights) ?? []
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        linkedSparkIds = try c.decodeIfPresent([UUID].self, forKey: .linkedSparkIds) ?? []
        voiceEntryIds = try c.decodeIfPresent([UUID].self, forKey: .voiceEntryIds) ?? []
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
