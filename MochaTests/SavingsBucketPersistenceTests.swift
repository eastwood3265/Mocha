import SwiftData
import XCTest
@testable import Mocha

@MainActor
final class SavingsBucketPersistenceTests: XCTestCase {
    func testEntryRelationshipSurvivesSaveAndRefetch() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SavingsBucket.self,
            SavingsBucketEntry.self,
            configurations: configuration
        )
        let context = container.mainContext
        let bucket = SavingsBucket(name: "旅行基金", targetAmount: 5_000)
        let entry = SavingsBucketEntry(bucket: bucket, type: .deposit, amount: 600)
        context.insert(bucket)
        context.insert(entry)
        try context.save()

        let fetchedBuckets = try context.fetch(FetchDescriptor<SavingsBucket>())
        let fetchedEntries = try context.fetch(FetchDescriptor<SavingsBucketEntry>())
        let fetchedBucket = try XCTUnwrap(fetchedBuckets.first)

        XCTAssertEqual(fetchedEntries.first?.bucket?.persistentModelID, fetchedBucket.persistentModelID)
        XCTAssertEqual(
            SavingsBucketProgressCalculator.balance(for: fetchedBucket, entries: fetchedEntries),
            600
        )
    }

    func testArchivingKeepsBucketAndEntries() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SavingsBucket.self,
            SavingsBucketEntry.self,
            configurations: configuration
        )
        let context = container.mainContext
        let bucket = SavingsBucket(name: "应急金")
        let entry = SavingsBucketEntry(bucket: bucket, type: .deposit, amount: 1_000)
        context.insert(bucket)
        context.insert(entry)
        bucket.isArchived = true
        try context.save()

        let fetchedBuckets = try context.fetch(FetchDescriptor<SavingsBucket>())
        let fetchedEntries = try context.fetch(FetchDescriptor<SavingsBucketEntry>())

        XCTAssertEqual(fetchedBuckets.count, 1)
        XCTAssertTrue(try XCTUnwrap(fetchedBuckets.first).isArchived)
        XCTAssertEqual(fetchedEntries.count, 1)
    }
}
