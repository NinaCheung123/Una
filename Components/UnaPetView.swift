//
//  UnaPetView.swift
//  Una
//
//  默认使用你新生成的可爱紫色小怪兽（抱着发光心的那个）
//

import SwiftUI

struct UnaPetView: View {
    var size: CGFloat = 140
    var message: String? = nil
    
    @State private var glowPulse: CGFloat = 0.6
    @State private var isBlinking = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // 温柔的光晕
                Circle()
                    .fill(UnaTheme.primary.opacity(0.25))
                    .frame(width: size * 1.35, height: size * 1.35)
                    .scaleEffect(glowPulse)
                    .blur(radius: 25)
                
                // 你的新可爱小怪兽图片
                Image("UnaPet")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .shadow(color: UnaTheme.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                
                // 眨眼动画层（可选叠加）
                if isBlinking {
                    Circle()
                        .fill(UnaTheme.primary)
                        .frame(width: size * 0.22, height: size * 0.08)
                        .offset(y: -size * 0.08)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    glowPulse = 0.95
                }
            }
            .onReceive(Timer.publish(every: 3.2, on: .main, in: .common).autoconnect()) { _ in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isBlinking = false
                    }
                }
            }
            
            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(UnaTheme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    ZStack {
        UnaTheme.background.ignoresSafeArea()
        UnaPetView(size: 180, message: "嘿～想跟我聊聊吗？🐾")
    }
}
