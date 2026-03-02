//
//  DiscoveryView.swift
//  Una
//
//  Deep Creature Discovery — user-first flow: list reasons → explore more → cross out → final + parking lot.
//

import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var newSparkText = ""
    @State private var selectedSpark: Spark?
    @State private var showingDiscoveryFlow = false
    @State private var showingResult = false
    
    var body: some View {
        ZStack {
            UnaTheme.softGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    UnaPetView(size: 90, message: "选一个今天的火花，一起探索～")
                        .padding(.top, 16)
                    
                    if !store.sparks.isEmpty {
                        Text("选择一条火花")
                            .font(.headline)
                            .foregroundStyle(UnaTheme.text)
                        LazyVStack(spacing: 10) {
                            ForEach(store.sparks.prefix(20)) { spark in
                                SparkRow(spark: spark) {
                                    selectedSpark = spark
                                    showingDiscoveryFlow = true
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("或写一条新的")
                            .font(.headline)
                            .foregroundStyle(UnaTheme.text)
                        TextField("今天的一个小想法...", text: $newSparkText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(UnaTheme.surface.opacity(0.8))
                            )
                            .lineLimit(3...6)
                        
                        Button("用这条开始探索") {
                            let spark = Spark(text: newSparkText)
                            store.addSpark(spark)
                            selectedSpark = spark
                            newSparkText = ""
                            showingDiscoveryFlow = true
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(UnaTheme.primary)
                        .disabled(newSparkText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("今日份探索自己")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { backButton } }
        .fullScreenCover(isPresented: $showingDiscoveryFlow) {
            if let spark = selectedSpark {
                DeepCreatureDiscoveryFlow(
                    spark: spark,
                    onDismiss: {
                        showingDiscoveryFlow = false
                        selectedSpark = nil
                    },
                    onComplete: {
                        showingResult = true
                        showingDiscoveryFlow = false
                    }
                )
                .environmentObject(store)
            }
        }
        .sheet(isPresented: $showingResult) {
            if let spark = selectedSpark, let updated = store.sparks.first(where: { $0.id == spark.id }) {
                DiscoveryResultSheet(spark: updated) {
                    showingResult = false
                    selectedSpark = nil
                }
                .environmentObject(store)
            }
        }
    }
    
    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(UnaTheme.text)
        }
    }
}

struct SparkRow: View {
    let spark: Spark
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(spark.text)
                    .font(.body)
                    .foregroundStyle(UnaTheme.text)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(UnaTheme.textSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(UnaTheme.cardGradient)
                    .shadow(color: UnaTheme.primary.opacity(0.1), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deep Creature Discovery Flow

struct DeepCreatureDiscoveryFlow: View {
    let spark: Spark
    let onDismiss: () -> Void
    let onComplete: () -> Void
    
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var sheetDismiss
    @StateObject private var voice = VoiceService()
    
    @State private var session: DiscoverySession
    @State private var newReasonInput = ""
    @State private var aiSuggestions: [String] = []
    @State private var showAiSuggestions = false
    @State private var lastCrossedIndex: Int? = nil
    @State private var editingIndex: Int? = nil
    @State private var editingText = ""
    @State private var reframingsForKept: [String] = []
    @State private var parkingLotItems: [String] = []
    
    init(spark: Spark, onDismiss: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.spark = spark
        self.onDismiss = onDismiss
        self.onComplete = onComplete
        _session = State(initialValue: DiscoverySession(sparkId: spark.id, sparkText: spark.text))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                UnaTheme.background.ignoresSafeArea()
                
                switch session.step {
                case .listing:
                    listingStep
                case .exploreMore:
                    exploreMoreStep
                case .crossingOut:
                    crossingOutStep
                case .finalReview:
                    finalReviewStep
                }
            }
            .navigationTitle("深挖")
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
        .task { await voice.requestAuthorization() }
    }
    
    // MARK: - Step 1: List reasons
    
    private var listingStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("把你想到的所有可能原因都列出来——哪怕概率很低、很乱也没关系。这个列举和划掉的过程，本身就是理解自己的过程。")
                    .font(.body)
                    .foregroundStyle(UnaTheme.text)
                
                // 添加原因输入
                HStack(spacing: 12) {
                    TextField("添加一个原因...", text: $newReasonInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addReasonFromInput() }
                    Button {
                        addReasonFromInput()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(UnaTheme.primary)
                    }
                }
                
                // 语音输入
                if voice.authorizationStatus == .authorized {
                    Button {
                        if voice.isRecording {
                            if let result = voice.stopRecording() {
                                Task { @MainActor in
                                    let t = await voice.transcribeFile(url: result.url)
                                    if !t.isEmpty { session.allReasons.append(t) }
                                }
                            }
                        } else {
                            voice.startRecording()
                        }
                    } label: {
                        HStack {
                            Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
                            Text(voice.isRecording ? "停止录音" : "语音输入")
                        }
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.primary)
                    }
                }
                
                // 已添加的原因列表（可删除）
                if !session.allReasons.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("你的原因（点右侧删除）")
                            .font(.headline)
                            .foregroundStyle(UnaTheme.text)
                        
                        ForEach(Array(session.allReasons.enumerated()), id: \.offset) { i, reason in
                            HStack {
                                Text("• \(reason)")
                                    .font(.body)
                                    .foregroundStyle(UnaTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button {
                                    session.allReasons.remove(at: i)
                                } label: {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundStyle(.red.opacity(0.8))
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Button("列完了") {
                    session.step = .exploreMore
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(UnaTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 16)
                .disabled(session.allReasons.isEmpty)
                .opacity(session.allReasons.isEmpty ? 0.6 : 1)
            }
            .padding(24)
        }
    }
    
    private func addReasonFromInput() {
        let t = newReasonInput.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty {
            session.allReasons.append(t)
            newReasonInput = ""
        }
    }
    
    // MARK: - Step 2: Explore more
    
    private var exploreMoreStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your reasons")
                    .font(.headline)
                    .foregroundStyle(UnaTheme.text)
                LazyVStack(spacing: 10) {
                    ForEach(Array(session.allReasons.enumerated()), id: \.offset) { i, r in
                        Text(r)
                            .font(.body)
                            .foregroundStyle(UnaTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(UnaTheme.cardGradient)
                            )
                    }
                }
                
                if !showAiSuggestions {
                    VStack(spacing: 12) {
                        Button {
                            showAiSuggestions = true
                            aiSuggestions = SummaryService.shared.suggestInitialReasons(for: spark.text)
                        } label: {
                            Text("想探索其他可能的原因吗？")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(UnaTheme.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        Button("直接进入划掉") {
                            session.step = .crossingOut
                        }
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.textSecondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Una 的建议")
                            .font(.headline)
                            .foregroundStyle(UnaTheme.text)
                        ForEach(aiSuggestions, id: \.self) { s in
                            if !session.allReasons.contains(s) {
                                Button {
                                    session.allReasons.append(s)
                                } label: {
                                    Text(s)
                                        .font(.body)
                                        .foregroundStyle(UnaTheme.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(UnaTheme.surface.opacity(0.8))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Button("进入划掉模式") {
                        session.step = .crossingOut
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 8)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Step 3: Crossing out
    
    private var crossingOutStep: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("点任意原因可划掉。下方可撤销。")
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.textSecondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                        ForEach(Array(session.allReasons.enumerated()), id: \.offset) { index, reason in
                            ReasonChip(
                                text: reason,
                                crossedOut: session.crossedOutIndices.contains(index)
                            ) {
                                var next = session.crossedOutIndices
                                if next.contains(index) {
                                    next.remove(index)
                                } else {
                                    next.insert(index)
                                    lastCrossedIndex = index
                                }
                                session.crossedOutIndices = next
                            }
                        }
                    }
                    
                    if let last = lastCrossedIndex {
                        Button("撤销上一次划掉") {
                            session.crossedOutIndices.remove(last)
                            lastCrossedIndex = nil
                        }
                        .font(.subheadline)
                        .foregroundStyle(UnaTheme.primary)
                    }
                    
                    Button("划完了") {
                        session.parkingLot = session.crossedOutReasons
                        reframingsForKept = session.keptReasons.map { SummaryService.shared.reframing(for: $0) }
                        session.step = .finalReview
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UnaTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
                .padding(24)
            }
            
            if session.canShowQuickAdd {
                VStack {
                    Spacer()
                    Button {
                        let newOnes = SummaryService.shared.suggestQuickReasons(for: spark.text, existing: session.allReasons)
                        session.allReasons.append(contentsOf: newOnes)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("快速添加更多选项")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(UnaTheme.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: UnaTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Step 4: Final review
    
    private var finalReviewStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("保留的原因（建议最多 3 个，你来决定）")
                    .font(.headline)
                    .foregroundStyle(UnaTheme.text)
                
                ForEach(Array(session.keptReasons.enumerated()), id: \.element) { i, r in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(r)
                            .font(.body)
                            .foregroundStyle(UnaTheme.text)
                        if i < reframingsForKept.count {
                            Text(reframingsForKept[i])
                                .font(.caption)
                                .foregroundStyle(UnaTheme.primary)
                                .italic()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(UnaTheme.cardGradient)
                    )
                }
                
                if !session.parkingLot.isEmpty {
                    Text("暂时还不想解决")
                        .font(.headline)
                        .foregroundStyle(UnaTheme.text)
                    ForEach(session.parkingLot, id: \.self) { p in
                        Text("• \(p)")
                            .font(.subheadline)
                            .foregroundStyle(UnaTheme.textSecondary)
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(UnaTheme.surface.opacity(0.7))
                    )
                }
                
                Button("保存") {
                    _ = store.saveDiscoveryFromSession(session, reframingsPerReason: reframingsForKept)
                    onComplete()
                    sheetDismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(UnaTheme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
}

struct ReasonChip: View {
    let text: String
    let crossedOut: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(crossedOut ? UnaTheme.textSecondary : UnaTheme.text)
                .strikethrough(crossedOut, color: UnaTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            crossedOut
                                ? AnyShapeStyle(UnaTheme.surface.opacity(0.6))
                                : AnyShapeStyle(UnaTheme.cardGradient)
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: crossedOut)
    }
}
// MARK: - Result sheet (when opening old discovery)

struct DiscoveryResultSheet: View {
    let spark: Spark
    let onClose: () -> Void
    
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var sheetDismiss
    
    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "zh_Hans")
        return f
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                UnaTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        evolutionTimelineSection
                        
                        UnaPetView(size: 80, message: spark.reframing ?? "你已经做得很好了～")
                        
                        if !spark.topReasons.isEmpty {
                            Text("最可能的原因")
                                .font(.headline)
                                .foregroundStyle(UnaTheme.text)
                            ForEach(Array(spark.topReasons.enumerated()), id: \.element) { i, r in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "leaf.fill")
                                            .foregroundStyle(UnaTheme.primary)
                                        Text(r)
                                            .foregroundStyle(UnaTheme.text)
                                    }
                                    if i < spark.reframingsPerReason.count {
                                        Text(spark.reframingsPerReason[i])
                                            .font(.caption)
                                            .foregroundStyle(UnaTheme.primary)
                                            .italic()
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        if !spark.parkingLot.isEmpty {
                            Text("暂时还不想解决")
                                .font(.headline)
                                .foregroundStyle(UnaTheme.text)
                            ForEach(spark.parkingLot, id: \.self) { p in
                                Text("• \(p)")
                                    .font(.subheadline)
                                    .foregroundStyle(UnaTheme.textSecondary)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("深挖结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onClose()
                        sheetDismiss()
                    }
                    .foregroundStyle(UnaTheme.primary)
                }
            }
        }
    }
    
    private var evolutionTimelineSection: some View {
        Group {
            let records = store.discoveryTimeline(for: spark.id)
            if records.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的理解在变化…")
                        .font(.headline)
                        .foregroundStyle(UnaTheme.text)
                    Text("看看你的小怪兽想法是怎么变的 ❤️")
                        .font(.caption)
                        .foregroundStyle(UnaTheme.textSecondary)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, rec in
                            HStack(alignment: .top, spacing: 8) {
                                Text(Self.dateFormatter.string(from: rec.date))
                                    .font(.caption)
                                    .foregroundStyle(UnaTheme.primary)
                                if index < records.count - 1 {
                                    Image(systemName: "arrow.down")
                                        .font(.caption2)
                                        .foregroundStyle(UnaTheme.textSecondary)
                                }
                            }
                            if !rec.topReasons.isEmpty {
                                Text(rec.topReasons.prefix(3).joined(separator: " → "))
                                    .font(.caption)
                                    .foregroundStyle(UnaTheme.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(UnaTheme.surface.opacity(0.7))
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiscoveryView()
            .environmentObject(UnaStore())
    }
}
