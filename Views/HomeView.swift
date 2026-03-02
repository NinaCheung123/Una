//
//  HomeView.swift
//  Una
//

import SwiftUI

struct HomeView: View {
    var onSelect: (MainTab) -> Void
    
    var body: some View {
        ZStack {
            UnaTheme.softGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)
                    
                    UnaPetView(size: 160, message: "Hey~ 想跟我聊聊吗？🐾")
                        .padding(.top, 8)
                    
                    VStack(spacing: 16) {
                        ForEach(MainTab.allCases, id: \.self) { tab in
                            HomeButton(title: tab.rawValue) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    onSelect(tab)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(UnaTheme.textSecondary)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeButton: View {
    let title: String
    let action: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(UnaTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(UnaTheme.cardGradient)
                        .shadow(color: UnaTheme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(UnaTheme.primary.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(pressed ? 0.97 : 1)
                .opacity(pressed ? 0.9 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                pressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    NavigationStack {
        HomeView(onSelect: { _ in })
            .environmentObject(UnaStore())
    }
}
