import SwiftData
import SwiftUI

struct GoldenBucketDashboardView: View {
    @Query(sort: \SavingsBucket.updatedAt, order: .reverse) private var buckets: [SavingsBucket]
    @Query(sort: \SavingsBucketEntry.occurredAt, order: .reverse) private var entries: [SavingsBucketEntry]
    @State private var showingBucketEditor = false
    @State private var showingEntryEditor = false
    @State private var showingArchivedBuckets = false

    private var activeBuckets: [SavingsBucket] {
        buckets.filter { !$0.isArchived }
    }

    private var summary: SavingsBucketSummary {
        SavingsBucketProgressCalculator.summary(for: activeBuckets, entries: entries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    GoldenBucketSummaryCard(summary: summary, bucketCount: activeBuckets.count)

                    if activeBuckets.isEmpty {
                        ContentUnavailableView(
                            "暂无金桶",
                            systemImage: "banknote",
                            description: Text("创建一个目标，开始记录每次存入和取出。")
                        )
                        .padding(.top, 44)
                    } else {
                        ForEach(activeBuckets) { bucket in
                            NavigationLink(value: bucket) {
                                SavingsBucketRow(
                                    progress: SavingsBucketProgressCalculator.progress(for: bucket, entries: entries)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("归档金桶", systemImage: "archivebox") {
                                    bucket.isArchived = true
                                    bucket.updatedAt = .now
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(MochaTheme.background)
            .navigationTitle("金桶")
            .navigationDestination(for: SavingsBucket.self) { bucket in
                SavingsBucketDetailView(bucket: bucket)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("归档", systemImage: "archivebox") {
                        showingArchivedBuckets = true
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("记流水", systemImage: "square.and.pencil") {
                        showingEntryEditor = true
                    }
                    .disabled(activeBuckets.isEmpty)
                    Button("添加金桶", systemImage: "plus") {
                        showingBucketEditor = true
                    }
                }
            }
            .sheet(isPresented: $showingBucketEditor) { SavingsBucketEditorView() }
            .sheet(isPresented: $showingEntryEditor) { SavingsBucketEntryEditorView() }
            .sheet(isPresented: $showingArchivedBuckets) { ArchivedSavingsBucketListView() }
        }
        .tint(MochaTheme.primaryText)
    }
}
