//
//  DiscoveryModel.swift
//  Una
//
//  Session state for Deep Creature Discovery flow.
//

import Foundation

/// In-memory state for a single discovery session (not persisted until save).
struct DiscoverySession {
    var sparkId: UUID
    var sparkText: String
    var allReasons: [String]
    var crossedOutIndices: Set<Int>
    var parkingLot: [String]
    var step: Step
    
    enum Step: Equatable {
        case listing
        case exploreMore
        case crossingOut
        case finalReview
    }
    
    init(sparkId: UUID, sparkText: String) {
        self.sparkId = sparkId
        self.sparkText = sparkText
        self.allReasons = []
        self.crossedOutIndices = []
        self.parkingLot = []
        self.step = .listing
    }
    
    var keptReasons: [String] {
        allReasons.enumerated()
            .filter { !crossedOutIndices.contains($0.offset) }
            .map(\.element)
    }
    
    var crossedOutReasons: [String] {
        allReasons.enumerated()
            .filter { crossedOutIndices.contains($0.offset) }
            .map(\.element)
    }
    
    var canShowQuickAdd: Bool {
        keptReasons.count > 3
    }
}
