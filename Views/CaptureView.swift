//
//  CaptureView.swift
//  Una
//
//  随时聊天 — record to file (kept forever) → transcribe → auto-tag → summary + insights.
//  Voice citation: "remind me last Tuesday X" / "link this to Y" → search & link.
//

import SwiftUI
import AVFoundation

struct CaptureView: View {
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voice = VoiceService()
    
    @State private var summaryText = ""
    @State private var insights: [String] = []
    @State private var tag: VoiceTag = .random
    @State private var savedEntry: VoiceEntry?
    @State private var showAuthAlert = false
    @State private var linkedSpark: Spark?
    
    var body: some View {
        ZStack {
            UnaTheme.softGradient.ignoresSafeArea()
            
            VStack(spacing: 28) {
                UnaPetView(size: 100,message: "说给我听吧～")
                    .padding(.top, 24)
                
                if voice.isRecording {
                    Text("正在录音...")
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.textSecondary)
                } else if voice.isTranscribing {
                    Text("正在转写...")
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.textSecondary)
                }
                
                if !voice.transcript.isEmpty && !voice.isRecording && !voice.isTranscribing {
                    transcriptCard
                }
                
                Spacer(minLength: 20)
                
                recordButton
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("随时聊天")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { backButton } }
        .task {
            await voice.requestAuthorization()
            if voice.authorizationStatus == .denied {
                showAuthAlert = true
            }
        }
        .alert("需要麦克风与语音识别", isPresented: $showAuthAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("请在 设置 → Una 中允许麦克风与语音识别，才能录音与转写。")
        }
        .sheet(item: $linkedSpark) { spark in
            VStack(alignment: .leading, spacing: 16) {
                Text("已关联到")
                    .font(.headline)
                Text(spark.text)
                    .font(.body)
                Button("关闭") { linkedSpark = nil }
                    .foregroundStyle(UnaTheme.primary)
            }
            .padding(24)
        }
    }
    
    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tag.icon)
                    .foregroundStyle(UnaTheme.primary)
                Text(tag.displayName)
                    .font(.caption)
                    .foregroundStyle(UnaTheme.textSecondary)
            }
            Text("转写内容")
                .font(.caption)
                .foregroundStyle(UnaTheme.textSecondary)
            Text(voice.transcript)
                .font(.body)
                .foregroundStyle(UnaTheme.text)
            
            if !summaryText.isEmpty {
                Divider().background(UnaTheme.accent.opacity(0.5))
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(UnaTheme.textSecondary)
                if !insights.isEmpty {
                    Text("✨ " + insights.prefix(3).joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(UnaTheme.primary.opacity(0.9))
                }
            }
            
            HStack {
                if summaryText.isEmpty && !voice.transcript.isEmpty {
                    Button("整理成日记") {
                        saveAndSummarize()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(UnaTheme.primary)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(UnaTheme.cardGradient)
                .shadow(color: UnaTheme.primary.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private func saveAndSummarize() {
        let (summary, insightList) = SummaryService.shared.summarize(transcript: voice.transcript)
        summaryText = summary
        insights = insightList
        tag = SummaryService.shared.autoTag(transcript: voice.transcript)
        
        let entry = VoiceEntry(
            transcript: voice.transcript,
            summary: summary,
            insights: insightList,
            tag: tag,
            audioFileName: lastRecordedFileName.isEmpty ? nil : lastRecordedFileName,
            linkedSparkIds: linkedSpark.map { [$0.id] } ?? []
        )
        store.addVoiceEntry(entry)
        savedEntry = entry
        
        if let linked = store.processCitationCommand(transcript: voice.transcript, sourceVoiceId: entry.id) {
            linkedSpark = linked
        }
    }
    
    @State private var lastRecordedFileName: String = ""
    
    private var recordButton: some View {
        Button {
            if voice.isRecording {
                if let result = voice.stopRecording() {
                    lastRecordedFileName = result.fileName
                    Task {
                        _ = await voice.transcribeFile(url: result.url)
                        tag = SummaryService.shared.autoTag(transcript: voice.transcript)
                    }
                }
            } else {
                voice.startRecording()
                lastRecordedFileName = ""
                summaryText = ""
                insights = []
                savedEntry = nil
            }
        } label: {
            ZStack {
                Circle()
                    .fill(UnaTheme.primaryGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: UnaTheme.primary.opacity(0.4), radius: 12, x: 0, y: 4)
                Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .scaleEffect(voice.isRecording ? 1.05 : 1)
            .animation(.easeInOut(duration: 0.2), value: voice.isRecording)
        }
        .buttonStyle(.plain)
    }
    
    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(UnaTheme.text)
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environmentObject(UnaStore())
    }
}
