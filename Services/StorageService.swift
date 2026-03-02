//
//  StorageService.swift
//  Una
//
//  All data in Documents as JSON + audio files. Settings in UserDefaults.
//

import Foundation

final class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let encouragementKey = "una_encouragement_phrases"
    private let eveningHourKey = "una_evening_hour"
    private let eveningMinuteKey = "una_evening_minute"
    private let onboardingDoneKey = "una_onboarding_done"
    private let openedFromNotificationKey = "una_opened_from_notification"
    
    var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var dataDirectory: URL {
        let url = documentsURL.appendingPathComponent("Data", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    var audioDirectory: URL {
        let url = documentsURL.appendingPathComponent("Audio", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    private init() {}
    
    // MARK: - JSON file paths
    
    private func fileURL(name: String) -> URL {
        dataDirectory.appendingPathComponent("\(name).json")
    }
    
    private func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        let url = fileURL(name: name)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    private func save<T: Encodable>(_ value: T, to name: String) {
        let url = fileURL(name: name)
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url)
    }
    
    // MARK: - Sparks
    
    func loadSparks() -> [Spark] {
        load([Spark].self, from: "sparks") ?? []
    }
    
    func saveSparks(_ sparks: [Spark]) {
        save(sparks, to: "sparks")
    }
    
    // MARK: - Daily Notes
    
    func loadDailyNotes() -> [DailyNote] {
        load([DailyNote].self, from: "daily_notes") ?? []
    }
    
    func saveDailyNotes(_ notes: [DailyNote]) {
        save(notes, to: "daily_notes")
    }
    
    // MARK: - Voice Entries
    
    func loadVoiceEntries() -> [VoiceEntry] {
        load([VoiceEntry].self, from: "voice_entries") ?? []
    }
    
    func saveVoiceEntries(_ entries: [VoiceEntry]) {
        save(entries, to: "voice_entries")
    }
    
    // MARK: - Spark Links
    
    func loadSparkLinks() -> [SparkLink] {
        load([SparkLink].self, from: "spark_links") ?? []
    }
    
    func saveSparkLinks(_ links: [SparkLink]) {
        save(links, to: "spark_links")
    }
    
    // MARK: - Discovery Records (timeline)
    
    func loadDiscoveryRecords() -> [DiscoveryRecord] {
        load([DiscoveryRecord].self, from: "discovery_records") ?? []
    }
    
    func saveDiscoveryRecords(_ records: [DiscoveryRecord]) {
        save(records, to: "discovery_records")
    }
    
    // MARK: - Encouragement phrases
    
    func loadEncouragementPhrases() -> [String] {
        if let list = defaults.stringArray(forKey: encouragementKey), !list.isEmpty {
            return list
        }
        return UnaTheme.defaultEncouragements
    }
    
    func saveEncouragementPhrases(_ phrases: [String]) {
        defaults.set(phrases, forKey: encouragementKey)
    }
    
    // MARK: - Evening notification time (default 9:30 PM)
    
    func loadEveningTime() -> (hour: Int, minute: Int) {
        let h = defaults.object(forKey: eveningHourKey) as? Int ?? 21
        let m = defaults.object(forKey: eveningMinuteKey) as? Int ?? 30
        return (h, m)
    }
    
    func saveEveningTime(hour: Int, minute: Int) {
        defaults.set(hour, forKey: eveningHourKey)
        defaults.set(minute, forKey: eveningMinuteKey)
    }
    
    // MARK: - Onboarding
    
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: onboardingDoneKey) }
        set { defaults.set(newValue, forKey: onboardingDoneKey) }
    }
    
    // MARK: - Opened from notification (show daily note sheet)
    
    var openedFromEveningNotification: Bool {
        get { defaults.bool(forKey: openedFromNotificationKey) }
        set { defaults.set(newValue, forKey: openedFromNotificationKey) }
    }
    
    // MARK: - Audio file path
    
    func audioURL(fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }
}
