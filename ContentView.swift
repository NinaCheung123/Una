//
//  ContentView.swift
//  Una
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject var store: UnaStore
    @State private var selectedTab: MainTab? = nil
    @State private var showOnboarding: Bool = !StorageService.shared.hasCompletedOnboarding
    @State private var showDailyNoteFromNotification = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else {
                NavigationStack {
                    HomeView(onSelect: { selectedTab = $0 })
                        .navigationDestination(item: $selectedTab) { tab in
                            switch tab {
                            case .chat:
                                CaptureView()
                            case .discovery:
                                DiscoveryView()
                            case .surprise:
                                RandomReviewView()
                            case .diary:
                                DailyNoteView()
                            }
                        }
                }
                .sheet(isPresented: $showDailyNoteFromNotification) {
                    NavigationStack {
                        DailyNoteView()
                            .environmentObject(store)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("关闭") { showDailyNoteFromNotification = false }
                                }
                            }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    if StorageService.shared.openedFromEveningNotification {
                        showDailyNoteFromNotification = true
                    }
                }
                .onAppear {
                    if StorageService.shared.openedFromEveningNotification {
                        showDailyNoteFromNotification = true
                    }
                }
            }
        }
    }
}

enum MainTab: String, Hashable, CaseIterable {
    case chat = "随时聊天"
    case discovery = "深挖今天"
    case surprise = "随机惊喜"
    case diary = "今天日记"
}

#Preview {
    ContentView()
        .environmentObject(UnaStore())
}
