//
//  SparkLink.swift
//  Una
//

import Foundation

struct SparkLink: Identifiable, Codable, Equatable {
    var id: UUID
    var sourceVoiceId: UUID?
    var sourceSparkId: UUID?
    var targetSparkId: UUID
    var quote: String
    var keyword: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        sourceVoiceId: UUID? = nil,
        sourceSparkId: UUID? = nil,
        targetSparkId: UUID,
        quote: String,
        keyword: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sourceVoiceId = sourceVoiceId
        self.sourceSparkId = sourceSparkId
        self.targetSparkId = targetSparkId
        self.quote = quote
        self.keyword = keyword
        self.createdAt = createdAt
    }
}
