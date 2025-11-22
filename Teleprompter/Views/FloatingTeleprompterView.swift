import SwiftUI

struct FloatingTeleprompterView: View {
    @Environment(\.dismiss) private var dismiss

    let script: Script
    let settings: TeleprompterSettings

    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling = true
    @State private var contentHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var timer: Timer?

    // 悬浮窗尺寸
    private let windowWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let windowHeight: CGFloat = 200

    var body: some View {
        ZStack {
            // 半透明背景，可以看到下面的内容
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景不做任何事
                }

            VStack {
                // 悬浮窗
                ZStack {
                    // 窗口背景
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.9))

                    VStack(spacing: 0) {
                        // 顶部工具栏
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                            }

                            Spacer()

                            // 画中画按钮（装饰性）
                            Image(systemName: "pip.enter")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                        // 滚动内容区域
                        GeometryReader { geometry in
                            ScrollViewReader { scrollProxy in
                                TeleprompterContentView(
                                    content: script.content,
                                    settings: settings,
                                    scrollOffset: $scrollOffset,
                                    contentHeight: $contentHeight,
                                    isScrolling: $isScrolling,
                                    onRestart: { restartScrolling() },
                                    onTogglePause: { togglePause() }
                                )
                                .onAppear {
                                    viewHeight = geometry.size.height
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    }
                }
                .frame(width: windowWidth, height: windowHeight)
                .rotationEffect(.degrees(Double(settings.rotation)))

                Spacer()
            }
            .padding(.top, 60)
        }
        .onAppear {
            startScrolling()
        }
        .onDisappear {
            stopScrolling()
        }
    }

    private func startScrolling() {
        isScrolling = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            if isScrolling {
                // 根据字号计算行高
                let lineHeight = settings.fontSize + 12
                // 每秒滚动的距离 = 行高 / 秒数
                let pointsPerSecond = lineHeight / CGFloat(settings.scrollSpeed)
                // 每帧滚动的距离 (30fps)
                let speed = pointsPerSecond / 30.0
                scrollOffset += speed
            }
        }
    }

    private func stopScrolling() {
        timer?.invalidate()
        timer = nil
    }

    private func togglePause() {
        isScrolling.toggle()
    }

    private func restartScrolling() {
        scrollOffset = 0
        isScrolling = true
    }
}

struct TeleprompterContentView: View {
    let content: String
    let settings: TeleprompterSettings
    @Binding var scrollOffset: CGFloat
    @Binding var contentHeight: CGFloat
    @Binding var isScrolling: Bool
    let onRestart: () -> Void
    let onTogglePause: () -> Void

    @State private var lastTapTime: Date = Date.distantPast

    var lines: [String] {
        content.components(separatedBy: .newlines)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    if !line.isEmpty {
                        Text(line)
                            .font(.system(size: settings.fontSize))
                            .foregroundColor(getColorForLine(at: index, in: geometry))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, geometry.size.height * 0.3)
            .padding(.bottom, geometry.size.height)
            .background(
                GeometryReader { contentGeometry in
                    Color.clear.onAppear {
                        contentHeight = contentGeometry.size.height
                    }
                }
            )
            .offset(y: -scrollOffset)
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onRestart()
        }
        .onTapGesture(count: 1) {
            onTogglePause()
        }
    }

    private func getColorForLine(at index: Int, in geometry: GeometryProxy) -> Color {
        // 计算当前行相对于视图的位置
        let lineHeight = settings.fontSize + 12
        let linePosition = CGFloat(index) * lineHeight + geometry.size.height * 0.3 - scrollOffset

        // 高亮区域在视图顶部 30% 的位置
        let highlightPosition = geometry.size.height * 0.3
        let highlightRange: CGFloat = lineHeight * 2

        if abs(linePosition - highlightPosition) < highlightRange {
            return settings.textColor
        } else {
            return .gray.opacity(0.7)
        }
    }
}

#Preview {
    FloatingTeleprompterView(
        script: Script(content: "这是第一行台词\n这是第二行台词\n这是第三行台词\n这是第四行台词"),
        settings: TeleprompterSettings()
    )
}
