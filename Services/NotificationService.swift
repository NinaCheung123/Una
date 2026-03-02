//
//  NotificationService.swift
//  Una
//
//  Daily evening reminder: "❤️ Una 问：今天想一起整理吗？"
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private let dailyCategoryId = "UNA_DAILY_ORGANIZE"
    private let dailyRequestId = "una_daily_evening"
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleDailyEvening() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyRequestId])
        
        let (hour, minute) = StorageService.shared.loadEveningTime()
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = "Una"
        content.body = "❤️ Una 问：今天想一起整理吗？"
        content.sound = .default
        content.categoryIdentifier = dailyCategoryId
        content.userInfo = ["action": "daily_organize"]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyRequestId, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func scheduleMorningReview() {
        let id = "una_morning_review"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Una"
        content.body = "早安～ 要看看随机火花吗？✨"
        content.sound = .default
        content.userInfo = ["action": "random_review"]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
