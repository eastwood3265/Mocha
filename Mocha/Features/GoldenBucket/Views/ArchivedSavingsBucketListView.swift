import SwiftData
import SwiftUI

struct ArchivedSavingsBucketListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavingsBucket.updatedAt, order: .reverse) private var buckets: [SavingsBucket]
    @Query private var entries: [SavingsBucketEntry]

    private var archivedBuckets: [SavingsBucket] {
        buckets.filter(\.isArchived)
    }

    var body: some View {
        NavigationStack {
            List {
                if archivedBuckets.isEmpty {
                    ContentUnavailableView(
                        "暂无归档金桶",
                        systemImage: "archivebox",
                        description: Text("归档后的金桶和历史流水会显示在这里。")
                    )
                } else {
                    ForEach(archivedBuckets) { bucket in
                        NavigationLink(value: bucket) {
                            SavingsBucketRow(
                                progress: SavingsBucketProgressCalculator.progress(for: bucket, entries: entries)
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle("归档金桶")
            .navigationDestination(for: SavingsBucket.self) { bucket in
                SavingsBucketDetailView(bucket: bucket)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .tint(MochaTheme.primaryText)
    }
}
