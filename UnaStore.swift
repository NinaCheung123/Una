//
//  UnaStore.swift
//  Una
//

import Foundation
import SwiftUI

final class UnaStore: ObservableObject {
    @Published var sparks: [Spark] = []
    @Published var dailyNotes: [DailyNote] = []
    @Published var voiceEntries: [VoiceEntry] = []
    @Published var sparkLinks: [SparkLink] = []
    @Published var discoveryRecords: [DiscoveryRecord] = []
    @Published var encouragementPhrases: [String] = []
    
    private let storage = StorageService.shared
    private let summaryService = SummaryService.shared
    private let citationService = CitationService.shared
    
    init() {
        loadAll()
    }
    
    func loadAll() {
        sparks = storage.loadSparks()
        dailyNotes = storage.loadDailyNotes()
        voiceEntries = storage.loadVoiceEntries()
        sparkLinks = storage.loadSparkLinks()
        discoveryRecords = storage.loadDiscoveryRecords()
        encouragementPhrases = storage.loadEncouragementPhrases()
    }
    
    func addSpark(_ spark: Spark) {
        sparks.insert(spark, at: 0)
        storage.saveSparks(sparks)
    }
    
    func updateSpark(_ spark: Spark) {
        if let i = sparks.firstIndex(where: { $0.id == spark.id }) {
            sparks[i] = spark
            storage.saveSparks(sparks)
        }
    }
    
    func addVoiceEntry(_ entry: VoiceEntry) {
        voiceEntries.insert(entry, at: 0)
        storage.saveVoiceEntries(voiceEntries)
    }
    
    func addDailyNote(_ note: DailyNote) {
        dailyNotes.insert(note, at: 0)
        storage.saveDailyNotes(dailyNotes)
    }
    
    func addSparkLink(_ link: SparkLink) {
        sparkLinks.append(link)
        storage.saveSparkLinks(sparkLinks)
    }
    
    func addDiscoveryRecord(_ record: DiscoveryRecord) {
        discoveryRecords.insert(record, at: 0)
        storage.saveDiscoveryRecords(discoveryRecords)
    }
    
    func randomSparks(count: Int = 5) -> [Spark] {
        let n = min(7, max(3, min(count, sparks.count)))
        return Array(sparks.shuffled().prefix(n))
    }
    
    func randomEncouragement() -> String {
        encouragementPhrases.randomElement() ?? "你今天已经很棒啦～"
    }
    
    func saveEncouragementPhrases(_ phrases: [String]) {
        encouragementPhrases = phrases
        storage.saveEncouragementPhrases(phrases)
    }
    
    func runDiscoveryFlow(for spark: Spark) -> Spark {
        var updated = spark
        if updated.discoveryReasons.isEmpty {
            updated.discoveryReasons = summaryService.generateDiscoveryReasons(for: spark.text)
        }
        let (top, reframing) = summaryService.refineToTopReasons(
            crossedOut: updated.crossedOutIndices,
            allReasons: updated.discoveryReasons
        )
        updated.topReasons = top
        updated.reframing = reframing
        
        let record = DiscoveryRecord(
            sparkId: updated.id,
            topReasons: top,
            reframing: reframing,
            sparkText: updated.text
        )
        addDiscoveryRecord(record)
        
        return updated
    }
    
    /// Save discovery from completed session (new user-first flow).
    func saveDiscoveryFromSession(_ session: DiscoverySession, reframingsPerReason: [String]) -> Spark {
        var spark = sparks.first(where: { $0.id == session.sparkId }) ?? Spark(id: session.sparkId, text: session.sparkText)
        spark.discoveryReasons = session.allReasons
        spark.crossedOutIndices = []
        spark.topReasons = session.keptReasons
        spark.reframingsPerReason = reframingsPerReason
        spark.parkingLot = session.parkingLot
        spark.lastDiscoveryDate = Date()
        spark.reframing = session.keptReasons.isEmpty ? nil : "你已经做得很好了～"
        
        let record = DiscoveryRecord(
            sparkId: session.sparkId,
            topReasons: session.keptReasons,
            reframing: spark.reframing,
            reframingsPerReason: reframingsPerReason,
            parkingLot: session.parkingLot,
            sparkText: session.sparkText
        )
        addDiscoveryRecord(record)
        
        if let i = sparks.firstIndex(where: { $0.id == spark.id }) {
            sparks[i] = spark
        } else {
            sparks.insert(spark, at: 0)
        }
        storage.saveSparks(sparks)
        
        return spark
    }
    
    func todayVoiceEntries() -> [VoiceEntry] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return voiceEntries.filter { $0.createdAt >= start && $0.createdAt < end }
    }
    
    func todaySparks() -> [Spark] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return sparks.filter { $0.createdAt >= start && $0.createdAt < end }
    }
    
    func processCitationCommand(transcript: String, sourceVoiceId: UUID?) -> Spark? {
        guard let cmd = citationService.parseCommand(from: transcript) else { return nil }
        let nearDate = cmd.dateHint
        let found = citationService.searchSparks(keyword: cmd.keyword, nearDate: nearDate, in: sparks)
        guard let target = found.first else { return nil }
        let link = SparkLink(
            sourceVoiceId: sourceVoiceId,
            targetSparkId: target.id,
            quote: target.text,
            keyword: cmd.keyword
        )
        addSparkLink(link)
        return target
    }
    
    func discoveryTimeline(for sparkId: UUID) -> [DiscoveryRecord] {
        discoveryRecords.filter { $0.sparkId == sparkId }
            .sorted { $0.date > $1.date }
    }
    
    func linksToSpark(_ sparkId: UUID) -> [SparkLink] {
        sparkLinks.filter { $0.targetSparkId == sparkId }
    }
}
