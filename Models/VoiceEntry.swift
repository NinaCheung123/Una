//
//  VoiceEntry.swift
//  Una
//

import Foundation

struct VoiceEntry: Identifiable, Codable {
    var id: UUID
    var transcript: String
    var summary: String?
    var insights: [String]
    var tag: VoiceTag
    var createdAt: Date
    var audioFileName: String?
    var linkedSparkIds: [UUID]
    
    init(
        id: UUID = UUID(),
        transcript: String,
        summary: String? = nil,
        insights: [String] = [],
        tag: VoiceTag = .random,
        createdAt: Date = Date(),
        audioFileName: String? = nil,
        linkedSparkIds: [UUID] = []
    ) {
        self.id = id
        self.transcript = transcript
        self.summary = summary
        self.insights = insights
        self.tag = tag
        self.createdAt = createdAt
        self.audioFileName = audioFileName
        self.linkedSparkIds = linkedSparkIds
    }
    
    enum CodingKeys: String, CodingKey {
        case id, transcript, summary, insights, tag, createdAt, audioFileName, linkedSparkIds
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        transcript = try c.decode(String.self, forKey: .transcript)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        insights = try c.decodeIfPresent([String].self, forKey: .insights) ?? []
        tag = (try? c.decode(VoiceTag.self, forKey: .tag)) ?? .random
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        audioFileName = try c.decodeIfPresent(String.self, forKey: .audioFileName)
        linkedSparkIds = try c.decodeIfPresent([UUID].self, forKey: .linkedSparkIds) ?? []
    }
}
