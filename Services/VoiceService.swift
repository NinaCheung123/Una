//
//  VoiceService.swift
//  Una
//
//  支持中文 + 英文语音识别，自动根据手机语言选择
//

import Foundation
import AVFoundation
import Speech

#if os(iOS)
import UIKit
#endif

@MainActor
final class VoiceService: NSObject, ObservableObject {
    
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var isTranscribing = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    private let recognizer: SFSpeechRecognizer?
    
    override init() {
        // 自动根据手机当前语言选择（优先中文，其次英文）
        let preferredLocale = Locale.current
        if SFSpeechRecognizer(locale: preferredLocale) != nil {
            recognizer = SFSpeechRecognizer(locale: preferredLocale)
        } else if preferredLocale.language.languageCode?.identifier == "zh" {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hans"))
        } else {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
        super.init()
    }
    
    func requestAuthorization() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    cont.resume()
                }
            }
        }
    }
    
    func startRecording() {
        transcript = ""
        errorMessage = nil
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    policy: .default,
                                    options: [.defaultToSpeaker, AVAudioSession.CategoryOptions.allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            errorMessage = "无法配置音频: \(error.localizedDescription)"
            return
        }
        
        let fileName = "\(UUID().uuidString).m4a"
        let url = StorageService.shared.audioURL(fileName: fileName)
        currentRecordingURL = url
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            errorMessage = "启动录音失败: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() -> (url: URL, fileName: String)? {
        guard let recorder = audioRecorder, let url = currentRecordingURL else {
            isRecording = false
            return nil
        }
        let fileName = url.lastPathComponent
        recorder.stop()
        audioRecorder = nil
        currentRecordingURL = nil
        isRecording = false
        
        return (url, fileName)
    }
    
    func transcribeFile(url: URL) async -> String {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            return ""
        }
        
        isTranscribing = true
        defer { isTranscribing = false }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        
        return await withCheckedContinuation { continuation in
            _ = recognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    Task { @MainActor in
                        self.transcript = text
                    }
                    if result.isFinal {
                        continuation.resume(returning: text)
                        return
                    }
                }
                
                // 如果有错误或没有得到最终结果
                if error != nil {
                    continuation.resume(returning: self.transcript)
                }
            }
        }
    }
}
