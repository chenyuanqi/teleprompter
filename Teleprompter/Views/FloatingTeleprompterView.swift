import SwiftUI
import SwiftData

struct FloatingTeleprompterView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var script: Script
    let settings: TeleprompterSettings

    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling = true
    @State private var contentHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var timer: Timer?
    @State private var windowPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: 150)
    @State private var backgroundOpacity: Double = 0.7
    @State private var showControls = true
    @State private var controlsTimer: Timer?

    // 悬浮窗尺寸
    @State private var windowWidth: CGFloat = UIScreen.main.bounds.width - 40
    @State private var windowHeight: CGFloat = 220

    var body: some View {
        ZStack {
            // 全透明背景，让相机画面完全可见
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleControls()
                }

            // 悬浮提词器窗口
            VStack(spacing: 0) {
                // 控制栏（自动隐藏）
                if showControls {
                    HStack(spacing: 16) {
                        // 关闭按钮
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }

                        Spacer()

                        // 背景透明度控制
                        Button(action: {
                            backgroundOpacity = backgroundOpacity > 0.3 ? 0.3 : 0.7
                        }) {
                            Image(systemName: backgroundOpacity > 0.5 ? "circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }

                        // 暂停/播放
                        Button(action: togglePause) {
                            Image(systemName: isScrolling ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }

                        // 重新开始
                        Button(action: restartScrolling) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.5))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 提词器窗口
                ZStack {
                    // 窗口背景
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(backgroundOpacity))

                    // 滚动内容区域
                    GeometryReader { geometry in
                        TeleprompterContentView(
                            content: script.content,
                            settings: settings,
                            scrollOffset: $scrollOffset,
                            contentHeight: $contentHeight,
                            isScrolling: $isScrolling,
                            onRestart: { },
                            onTogglePause: { }
                        )
                        .onAppear {
                            viewHeight = geometry.size.height
                        }
                    }
                    .padding(16)
                }
                .frame(width: windowWidth, height: windowHeight)
                .rotationEffect(.degrees(Double(settings.rotation)))
                .shadow(color: .black.opacity(0.3), radius: 10)

                Spacer()
            }
            .padding(.top, showControls ? 70 : 20)
        }
        .onAppear {
            startScrolling()
            startControlsTimer()
        }
        .onDisappear {
            stopScrolling()
            stopControlsTimer()
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
        resetControlsTimer()
    }

    private func restartScrolling() {
        scrollOffset = 0
        isScrolling = true
        resetControlsTimer()
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        if showControls {
            resetControlsTimer()
        }
    }

    private func startControlsTimer() {
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }

    private func stopControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }

    private func resetControlsTimer() {
        stopControlsTimer()
        startControlsTimer()
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
