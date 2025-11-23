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

    // 颜色转换辅助方法
    static func colorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255),
                     Int(alpha * 255))
    }

    static func hexToColor(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF000000) >> 24) / 255.0
        let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
        let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
        let a = Double(rgb & 0x000000FF) / 255.0

        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
