//
//  OnboardingView.swift
//  Una
//
//  First launch: welcome Una, gentle permissions, ready.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var page = 0
    
    var body: some View {
        ZStack {
            UnaTheme.softGradient.ignoresSafeArea()
            
            VStack(spacing: 32) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    permissionsPage.tag(1)
                    readyPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)
                
                pageIndicator
                
                if page < 2 {
                    Button("下一步") {
                        withAnimation { page += 1 }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                } else {
                    Button("开始和 Una 一起玩吧") {
                        StorageService.shared.hasCompletedOnboarding = true
                        onComplete()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                }
                
                Spacer().frame(height: 48)
            }
        }
    }
    
    private var welcomePage: some View {
        VStack(spacing: 28) {
            UnaPetView(size: 160, message: nil)
            
            Text("嘿，我是 Una 🐾")
                .font(.largeTitle.bold())
                .foregroundStyle(UnaTheme.text)
            
            Text("你的小怪兽朋友\n随时陪你记录想法、一起懂自己")
                .font(.title3)
                .foregroundStyle(UnaTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }
    
    private var permissionsPage: some View {
        VStack(spacing: 28) {
            Image(systemName: "mic.fill")
                .font(.system(size: 68))
                .foregroundStyle(UnaTheme.primary)
            
            Text("Una 想听你说话")
                .font(.title2.bold())
                .foregroundStyle(UnaTheme.text)
            
            Text("需要麦克风来录音\n需要语音识别把你说的话转成文字\n\n所有内容都只保存在你的手机里，放心～")
                .font(.body)
                .foregroundStyle(UnaTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 40)
    }
    
    private var readyPage: some View {
        VStack(spacing: 28) {
            UnaPetView(size: 140, message: "我们开始吧？")
            
            Text("一切都准备好了")
                .font(.title2.bold())
                .foregroundStyle(UnaTheme.text)
            
            Text("随时语音记录\n深挖今天的感受\n随机看到过去的自己\n\nUna 会一直在这里陪着你")
                .font(.body)
                .foregroundStyle(UnaTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 40)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(page == i ? UnaTheme.primary : UnaTheme.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
