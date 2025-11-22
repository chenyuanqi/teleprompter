import Foundation
import SwiftData

@Model
final class Script {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "", content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        return firstLine.isEmpty ? "未命名台词" : String(firstLine.prefix(20))
    }

    var previewContent: String {
        let lines = content.components(separatedBy: .newlines)
        let preview = lines.prefix(2).joined(separator: " ")
        return String(preview.prefix(50))
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: updatedAt)
    }
}
