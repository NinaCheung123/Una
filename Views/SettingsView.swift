//
//  SettingsView.swift
//  Una
//
//  Evening notification time + encouragement phrases + 重新观看欢迎页
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var phrases: [String] = []
    @State private var newPhrase = ""
    @State private var eveningDate: Date = {
        let (h, m) = StorageService.shared.loadEveningTime()
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = h
        c.minute = m
        return Calendar.current.date(from: c) ?? Date()
    }()
    
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
            UnaTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    UnaPetView(size: 80, message: "在这里调整 Una 的鼓励语与提醒时间～")
                        .padding(.top, 16)
                    
                    Text("每日整理提醒")
                        .font(.headline)
                        .foregroundStyle(UnaTheme.text)
                    Text("每天此时 Una 会问：今天想一起整理吗？")
                        .font(.caption)
                        .foregroundStyle(UnaTheme.textSecondary)
                    DatePicker("时间", selection: $eveningDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .onChange(of: eveningDate) { _, newValue in
                            let cal = Calendar.current
                            let h = cal.component(.hour, from: newValue)
                            let m = cal.component(.minute, from: newValue)
                            StorageService.shared.saveEveningTime(hour: h, minute: m)
                            NotificationService.shared.scheduleDailyEvening()
                        }
                        .tint(UnaTheme.primary)
                    
                    Text("每日鼓励语（5–6 句）")
                        .font(.headline)
                        .foregroundStyle(UnaTheme.text)
                    
                    ForEach(phrases.indices, id: \.self) { i in
                        HStack {
                            TextField("鼓励语", text: $phrases[i])
                                .textFieldStyle(.roundedBorder)
                            Button {
                                phrases.remove(at: i)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(UnaTheme.primary.opacity(0.8))
                            }
                        }
                    }
                    
                    HStack {
                        TextField("新增一句", text: $newPhrase)
                            .textFieldStyle(.roundedBorder)
                        Button("添加") {
                            let t = newPhrase.trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty {
                                phrases.append(t)
                                newPhrase = ""
                            }
                        }
                        .foregroundStyle(UnaTheme.primary)
                        .disabled(newPhrase.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    Button("保存") {
                        store.saveEncouragementPhrases(phrases.isEmpty ? UnaTheme.defaultEncouragements : phrases)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 12)
                    
                    // 重新观看欢迎页按钮
                    Button {
                        StorageService.shared.hasCompletedOnboarding = false
                        showingOnboarding = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("再看一次 Una 的故事 🐾")
                        }
                        .foregroundStyle(UnaTheme.primary)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(UnaTheme.text)
                }
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(onComplete: {
                showingOnboarding = false
            })
        }
        .onAppear {
            phrases = store.encouragementPhrases
            let (h, m) = StorageService.shared.loadEveningTime()
            var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            c.hour = h
            c.minute = m
            eveningDate = Calendar.current.date(from: c) ?? eveningDate
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(UnaStore())
    }
}
