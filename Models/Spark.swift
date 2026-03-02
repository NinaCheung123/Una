//
//  Spark.swift
//  Una
//

import Foundation

struct Spark: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var createdAt: Date
    var discoveryReasons: [String]
    var crossedOutIndices: Set<Int>
    var topReasons: [String]
    var reframing: String?
    var reframingsPerReason: [String]
    var parkingLot: [String]
    var linkedDiscoveryIds: [UUID]
    var lastDiscoveryDate: Date?
    
    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        discoveryReasons: [String] = [],
        crossedOutIndices: Set<Int> = [],
        topReasons: [String] = [],
        reframing: String? = nil,
        reframingsPerReason: [String] = [],
        parkingLot: [String] = [],
        linkedDiscoveryIds: [UUID] = [],
        lastDiscoveryDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.discoveryReasons = discoveryReasons
        self.crossedOutIndices = crossedOutIndices
        self.topReasons = topReasons
        self.reframing = reframing
        self.reframingsPerReason = reframingsPerReason
        self.parkingLot = parkingLot
        self.linkedDiscoveryIds = linkedDiscoveryIds
        self.lastDiscoveryDate = lastDiscoveryDate
    }
}

extension Spark {
    static let sample = Spark(
        text: "今天有点累，但完成了重要的事",
        discoveryReasons: ["睡眠不足", "任务多", "天气影响", "情绪波动", "运动少", "社交多", "期待高", "节奏快"],
        topReasons: ["任务多", "期待高"],
        reframing: "累是因为你在认真生活呀～"
    )
}

extension Spark {
    enum CodingKeys: String, CodingKey {
        case id, text, createdAt, discoveryReasons, crossedOutIndices, topReasons, reframing,
             reframingsPerReason, parkingLot, linkedDiscoveryIds, lastDiscoveryDate
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        discoveryReasons = try c.decode([String].self, forKey: .discoveryReasons)
        crossedOutIndices = try c.decodeIfPresent(Set<Int>.self, forKey: .crossedOutIndices) ?? []
        topReasons = try c.decodeIfPresent([String].self, forKey: .topReasons) ?? []
        reframing = try c.decodeIfPresent(String.self, forKey: .reframing)
        reframingsPerReason = try c.decodeIfPresent([String].self, forKey: .reframingsPerReason) ?? []
        parkingLot = try c.decodeIfPresent([String].self, forKey: .parkingLot) ?? []
        linkedDiscoveryIds = try c.decodeIfPresent([UUID].self, forKey: .linkedDiscoveryIds) ?? []
        lastDiscoveryDate = try c.decodeIfPresent(Date.self, forKey: .lastDiscoveryDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(discoveryReasons, forKey: .discoveryReasons)
        try c.encode(crossedOutIndices, forKey: .crossedOutIndices)
        try c.encode(topReasons, forKey: .topReasons)
        try c.encodeIfPresent(reframing, forKey: .reframing)
        try c.encode(reframingsPerReason, forKey: .reframingsPerReason)
        try c.encode(parkingLot, forKey: .parkingLot)
        try c.encode(linkedDiscoveryIds, forKey: .linkedDiscoveryIds)
        try c.encodeIfPresent(lastDiscoveryDate, forKey: .lastDiscoveryDate)
    }
}
