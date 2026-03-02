//
//  DailyNoteView.swift
//  Una
//
//  End-of-day: collect today's sparks → Daily Creature Note (raw voices + transcripts + summary + tags + insights).
//

import SwiftUI

struct DailyNoteView: View {
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var rawVoiceInput = ""
    @State private var generatedNote: DailyNote?
    @State private var showCollectToday = false
    
    private var todayString: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "zh_Hans")
        return f.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            UnaTheme.softGradient.ignoresSafeArea()
            
            if let note = generatedNote {
                dailyNoteDetail(note)
            } else {
                inputForm
            }
        }
        .navigationTitle("今天日记")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { backButton }
            if generatedNote != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("新建") {
                        generatedNote = nil
                        rawVoiceInput = ""
                    }
                    .foregroundStyle(UnaTheme.primary)
                }
            }
        }
        .onAppear {
            if StorageService.shared.openedFromEveningNotification {
                StorageService.shared.openedFromEveningNotification = false
                showCollectToday = true
            }
        }
        .sheet(isPresented: $showCollectToday) {
            CollectTodaySheet(
                onDismiss: { showCollectToday = false },
                onGenerated: { note in
                    generatedNote = note
                    showCollectToday = false
                }
            )
            .environmentObject(store)
        }
    }
    
    private var inputForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                UnaPetView(size: 90, message: "把今天想留住的，写下来吧～")
                    .padding(.top, 16)
                
                Button {
                    showCollectToday = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("收集今天的火花，生成日记")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Text("或手动输入今日随记")
                    .font(.headline)
                    .foregroundStyle(UnaTheme.text)
                
                TextEditor(text: $rawVoiceInput)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundStyle(UnaTheme.text)
                    .frame(minHeight: 160)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(UnaTheme.cardGradient)
                            .shadow(color: UnaTheme.primary.opacity(0.12), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(UnaTheme.primary.opacity(0.25), lineWidth: 1)
                    )
                
                Button {
                    let (summary, insights) = SummaryService.shared.summarize(transcript: rawVoiceInput)
                    let note = DailyNote(
                        date: Date(),
                        rawVoiceText: rawVoiceInput,
                        rawTranscripts: [rawVoiceInput],
                        summary: summary,
                        insights: insights,
                        tags: [SummaryService.shared.autoTag(transcript: rawVoiceInput).displayName],
                        linkedSparkIds: store.sparks.prefix(5).map(\.id)
                    )
                    store.addDailyNote(note)
                    generatedNote = note
                } label: {
                    Text("生成今日日记")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(UnaTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(rawVoiceInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(rawVoiceInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func dailyNoteDetail(_ note: DailyNote) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text(todayString)
                    .font(.subheadline)
                    .foregroundStyle(UnaTheme.textSecondary)
                
                if !note.rawTranscripts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("原文 / 转写")
                            .font(.caption)
                            .foregroundStyle(UnaTheme.textSecondary)
                        ForEach(Array(note.rawTranscripts.enumerated()), id: \.offset) { _, t in
                            Text(t)
                                .font(.body)
                                .foregroundStyle(UnaTheme.text)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(UnaTheme.surface.opacity(0.7))
                    )
                }
                
                if !note.rawVoiceText.isEmpty && note.rawTranscripts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("原文")
                            .font(.caption)
                            .foregroundStyle(UnaTheme.textSecondary)
                        Text(note.rawVoiceText)
                            .font(.body)
                            .foregroundStyle(UnaTheme.text)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(UnaTheme.surface.opacity(0.7))
                    )
                }
                
                if !note.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundStyle(UnaTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(UnaTheme.surface.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Una 小结")
                        .font(.caption)
                        .foregroundStyle(UnaTheme.textSecondary)
                    Text(note.summary)
                        .font(.body)
                        .foregroundStyle(UnaTheme.text)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(UnaTheme.cardGradient)
                        .shadow(color: UnaTheme.primary.opacity(0.1), radius: 6, x: 0, y: 2)
                )
                
                if !note.insights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✨ 小洞察")
                            .font(.caption)
                            .foregroundStyle(UnaTheme.textSecondary)
                        ForEach(note.insights, id: \.self) { i in
                            Text("• \(i)")
                                .font(.subheadline)
                                .foregroundStyle(UnaTheme.text)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(UnaTheme.surface.opacity(0.6))
                    )
                }
                
                if !note.linkedSparkIds.isEmpty {
                    Text("相关火花")
                        .font(.headline)
                        .foregroundStyle(UnaTheme.text)
                    ForEach(store.sparks.filter { note.linkedSparkIds.contains($0.id) }) { s in
                        Text(s.text)
                            .font(.subheadline)
                            .foregroundStyle(UnaTheme.textSecondary)
                            .padding(.vertical, 6)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
    
    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(UnaTheme.text)
        }
    }
}

struct CollectTodaySheet: View {
    let onDismiss: () -> Void
    let onGenerated: (DailyNote) -> Void
    
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var sheetDismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                UnaTheme.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    UnaPetView(size: 90, message: "收集今天的所有火花，做成一份日记～")
                    let voices = store.todayVoiceEntries()
                    let todaySparks = store.todaySparks()
                    Text("今天有 \(voices.count) 条语音，\(todaySparks.count) 条火花")
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.textSecondary)
                    Button("生成今日 Creature 日记") {
                        let transcripts = voices.map(\.transcript)
                        let allText = transcripts.joined(separator: "\n\n")
                        let (summary, insights) = SummaryService.shared.summarize(transcript: allText.isEmpty ? todaySparks.map(\.text).joined(separator: " ") : allText)
                        let tags = voices.map { SummaryService.shared.autoTag(transcript: $0.transcript).displayName }
                        let uniqueTags = Array(Set(tags))
                        let note = DailyNote(
                            date: Date(),
                            rawVoiceText: allText,
                            rawTranscripts: transcripts,
                            summary: summary,
                            insights: insights,
                            tags: uniqueTags,
                            linkedSparkIds: todaySparks.map(\.id),
                            voiceEntryIds: voices.map(\.id)
                        )
                        store.addDailyNote(note)
                        onGenerated(note)
                        sheetDismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("收集今天")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                        sheetDismiss()
                    }
                    .foregroundStyle(UnaTheme.text)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DailyNoteView()
            .environmentObject(UnaStore())
    }
}
