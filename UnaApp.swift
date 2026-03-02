import SwiftUI

#if os(iOS)
import UIKit
import UserNotifications
#endif

@main
struct UnaApp: App {
    @StateObject private var store = UnaStore()
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

#if os(iOS)
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Task {
            _ = await NotificationService.shared.requestAuthorization()
            NotificationService.shared.scheduleDailyEvening()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["action"] as? String == "daily_organize" {
            StorageService.shared.openedFromEveningNotification = true
        }
        completionHandler()
    }
}
#endif
