import Foundation
import SwiftData

enum StorageLocationType: String, Codable, CaseIterable, Identifiable {
    case brokerage = "证券账户"
    case bondPlatform = "债券平台"
    case bank = "银行"
    case physical = "实物保管"
    case other = "其他"

    var id: Self { self }
}

@Model
final class StorageLocation {
    var name: String
    var typeRawValue: String
    var institution: String
    var accountAlias: String
    var accountSuffix: String
    var note: String
    var createdAt: Date

    var type: StorageLocationType {
        get { StorageLocationType(rawValue: typeRawValue) ?? .other }
        set { typeRawValue = newValue.rawValue }
    }

    init(name: String, type: StorageLocationType, institution: String = "", accountAlias: String = "", accountSuffix: String = "", note: String = "") {
        self.name = name
        self.typeRawValue = type.rawValue
        self.institution = institution
        self.accountAlias = accountAlias
        self.accountSuffix = accountSuffix
        self.note = note
        self.createdAt = .now
    }
}
