import SwiftUI

struct TeleprompterSettings {
    var scrollSpeed: Double = 3.0  // 1.0 - 10.0 秒每行
    var fontSize: CGFloat = 24
    var rotation: Int = 0  // 0, 90, 180, 270
    var textColor: Color = .green

    static let availableColors: [Color] = [
        .white,
        Color(red: 1.0, green: 0.4, blue: 0.4),    // 红
        Color(red: 1.0, green: 0.6, blue: 0.2),    // 橙
        Color(red: 1.0, green: 0.8, blue: 0.3),    // 黄橙
        Color(red: 0.8, green: 1.0, blue: 0.4),    // 黄绿
        Color(red: 0.2, green: 0.9, blue: 0.4),    // 绿
        Color(red: 0.3, green: 1.0, blue: 0.8),    // 青
        Color(red: 0.4, green: 0.8, blue: 1.0),    // 蓝
    ]
}
