//
//  RandomReviewView.swift
//  Una
//
//  Flomo-style: 3–7 random sparks, Una message, Still on my mind / Deep dive / Skip.
//

import SwiftUI

struct RandomReviewView: View {
    @EnvironmentObject var store: UnaStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var shownSparks: [Spark] = []
    @State private var encouragement: String = ""
    @State private var appeared = false
    @State private var selectedSparkForDiscovery: Spark?
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            UnaTheme.softGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    UnaPetView(
                        size: 110,
                        message: encouragement.isEmpty ? "随机看看以前的火花吧～" : encouragement
                    )
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                    
                    if shownSparks.isEmpty && store.sparks.isEmpty {
                        Text("还没有火花哦\n先去「随时聊天」或「深挖今天」记一点吧～")
                            .font(.body)
                            .foregroundStyle(UnaTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(32)
                    } else if shownSparks.isEmpty {
                        ProgressView()
                            .tint(UnaTheme.primary)
                            .padding()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(Array(shownSparks.enumerated()), id: \.element.id) { index, spark in
                                SparkReviewCard(
                                    spark: spark,
                                    onStillOnMind: { },
                                    onDeepDive: { selectedSparkForDiscovery = spark },
                                    onSkip: {
                                        withAnimation {
                                            if let i = shownSparks.firstIndex(where: { $0.id == spark.id }) {
                                                shownSparks.remove(at: i)
                                            }
                                            if shownSparks.isEmpty { refreshRandom() }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Button("再抽一次") {
                            refreshRandom()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(UnaTheme.primary)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("随机惊喜")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { backButton } }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            refreshRandom()
        }
        .sheet(item: $selectedSparkForDiscovery) { spark in
            DeepCreatureDiscoveryFlow(
                spark: spark,
                onDismiss: { selectedSparkForDiscovery = nil },
                onComplete: { selectedSparkForDiscovery = nil }
            )
            .environmentObject(store)
        }
    }
    
    private func refreshRandom() {
        let count = min(7, max(3, store.sparks.count))
        shownSparks = store.randomSparks(count: count)
        currentIndex = 0
        encouragement = store.randomEncouragement()
    }
    
    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(UnaTheme.text)
        }
    }
}

struct SparkReviewCard: View {
    let spark: Spark
    let onStillOnMind: () -> Void
    let onDeepDive: () -> Void
    let onSkip: () -> Void
    
    @State private var revealed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(spark.text)
                .font(.body)
                .foregroundStyle(UnaTheme.text)
                .multilineTextAlignment(.leading)
            
            if let ref = spark.reframing, !ref.isEmpty {
                Text(ref)
                    .font(.caption)
                    .foregroundStyle(UnaTheme.textSecondary)
                    .italic()
            }
            
            Text(spark.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(UnaTheme.textSecondary.opacity(0.8))
            
            HStack(spacing: 12) {
                Button("还在想") {
                    onStillOnMind()
                }
                .font(.caption)
                .foregroundStyle(UnaTheme.primary)
                Button("深挖") {
                    onDeepDive()
                }
                .font(.caption)
                .foregroundStyle(UnaTheme.primary)
                Button("跳过") {
                    onSkip()
                }
                .font(.caption)
                .foregroundStyle(UnaTheme.textSecondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(UnaTheme.cardGradient)
                .shadow(color: UnaTheme.primary.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(UnaTheme.primary.opacity(0.2), lineWidth: 1)
        )
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { revealed = true }
        }
    }
}

extension Spark: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: Spark, rhs: Spark) -> Bool { lhs.id == rhs.id }
}

#Preview {
    NavigationStack {
        RandomReviewView()
            .environmentObject(UnaStore())
    }
}
