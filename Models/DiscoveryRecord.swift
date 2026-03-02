//
//  DiscoveryRecord.swift
//  Una
//

import Foundation

struct DiscoveryRecord: Identifiable, Codable {
    var id: UUID
    var sparkId: UUID
    var date: Date
    var topReasons: [String]
    var reframing: String?
    var reframingsPerReason: [String]
    var parkingLot: [String]
    var sparkText: String
    
    init(
        id: UUID = UUID(),
        sparkId: UUID,
        date: Date = Date(),
        topReasons: [String],
        reframing: String? = nil,
        reframingsPerReason: [String] = [],
        parkingLot: [String] = [],
        sparkText: String
    ) {
        self.id = id
        self.sparkId = sparkId
        self.date = date
        self.topReasons = topReasons
        self.reframing = reframing
        self.reframingsPerReason = reframingsPerReason
        self.parkingLot = parkingLot
        self.sparkText = sparkText
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        sparkId = try c.decode(UUID.self, forKey: .sparkId)
        date = try c.decode(Date.self, forKey: .date)
        topReasons = try c.decode([String].self, forKey: .topReasons)
        reframing = try c.decodeIfPresent(String.self, forKey: .reframing)
        reframingsPerReason = try c.decodeIfPresent([String].self, forKey: .reframingsPerReason) ?? []
        parkingLot = try c.decodeIfPresent([String].self, forKey: .parkingLot) ?? []
        sparkText = try c.decode(String.self, forKey: .sparkText)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, sparkId, date, topReasons, reframing, reframingsPerReason, parkingLot, sparkText
    }
}
