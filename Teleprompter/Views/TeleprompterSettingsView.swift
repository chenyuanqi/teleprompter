import SwiftUI
import SwiftData
import AVKit
import AVFoundation

struct TeleprompterSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var script: Script

    // 使用 @AppStorage 持久化存储设置
    @AppStorage("scrollSpeed") private var scrollSpeed: Double = 3.0
    @AppStorage("fontSize") private var fontSize: Double = 24.0
    @AppStorage("rotation") private var rotation: Int = 0
    @AppStorage("textColorHex") private var textColorHex: String = "#33CC66FF"

    @StateObject private var pipController = PiPTeleprompterController()

    // 计算属性：从存储的值创建 settings 对象
    private var settings: TeleprompterSettings {
        TeleprompterSettings(
            scrollSpeed: scrollSpeed,
            fontSize: CGFloat(fontSize),
            rotation: rotation,
            textColor: TeleprompterSettings.hexToColor(textColorHex)
        )
    }

    // 辅助方法：比较两个颜色是否相等
    private func areColorsEqual(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = TeleprompterSettings.colorToHex(color1)
        let hex2 = TeleprompterSettings.colorToHex(color2)
        return hex1 == hex2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 隐藏的播放器视图 - 用于画中画
                if pipController.playerLayer != nil {
                    PlayerLayerView(playerLayer: pipController.playerLayer!)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }

                VStack(spacing: 0) {
                    // 预览区域 - 固定在顶部
                    PreviewCard(content: script.content, settings: settings)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)

                // 可滚动的设置区域
                ScrollView {
                    VStack(spacing: 24) {
                        // 滚动速度
                        SettingSlider(
                            title: "滚动速度",
                            value: $scrollSpeed,
                            range: 1.0...10.0,
                            valueFormatter: { String(format: "%.1f 秒/行", $0) }
                        )

                        // 字号
                        SettingSlider(
                            title: "字号",
                            value: $fontSize,
                            range: 16...48,
                            valueFormatter: { String(format: "%.0f", $0) }
                        )

                        // 文字旋转
                        HStack {
                            Text("文字旋转")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                rotation = (rotation + 90) % 360
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.portrait.rotate")
                                    Text("\(rotation)°")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(white: 0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)

                        // 文字颜色
                        VStack(alignment: .leading, spacing: 12) {
                            Text("文字颜色")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(TeleprompterSettings.availableColors.enumerated()), id: \.offset) { index, color in
                                        ColorButton(
                                            color: color,
                                            isSelected: {
                                                let colorHex = TeleprompterSettings.colorToHex(color)
                                                return colorHex == textColorHex
                                            }(),
                                            action: {
                                                textColorHex = TeleprompterSettings.colorToHex(color)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 20)
                }
                .background(Color.black)

                // 底部按钮
                VStack(spacing: 16) {
                    // 状态显示 - 只显示错误信息
                    if let errorMessage = pipController.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                    }

                    // 主按钮
                    if pipController.isActive {
                        Button(action: {
                            pipController.stopPiP()
                        }) {
                            HStack {
                                Image(systemName: "pip.exit")
                                    .font(.system(size: 20))
                                Text("停止悬浮提词")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(28)
                        }
                    } else {
                        Button(action: {
                            pipController.startPiP(script: script, settings: settings)
                        }) {
                            HStack {
                                if pipController.isGeneratingVideo {
                                    ProgressView()
                                        .tint(.white)
                                    Text("正在加载...")
                                        .font(.system(size: 18, weight: .medium))
                                } else {
                                    Image(systemName: "pip.enter")
                                        .font(.system(size: 20))
                                    Text("开启悬浮提词")
                                        .font(.system(size: 18, weight: .medium))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 1.0, green: 0.3, blue: 0.4))
                            .cornerRadius(28)
                        }
                        .disabled(!pipController.isPiPSupported || pipController.isGeneratingVideo)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(Color.black)
                }
            }
            .background(Color.black)
            .navigationTitle("悬浮提词预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            // 页面关闭时不停止 PiP，让它继续运行
        }
    }
}

struct PreviewCard: View {
    let content: String
    let settings: TeleprompterSettings

    var lines: [String] {
        content.components(separatedBy: .newlines)
    }

    var body: some View {
        ZStack {
            // 背景框 - 不旋转
            Color(white: 0.12)
                .ignoresSafeArea(edges: .top)

            // 可滚动的内容区域 - 旋转
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        if !line.isEmpty {
                            Text(line)
                                .font(.system(size: settings.fontSize))
                                .foregroundColor(settings.textColor)
                        } else {
                            // 保留空行
                            Text(" ")
                                .font(.system(size: settings.fontSize))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .rotationEffect(.degrees(Double(settings.rotation)))
        }
    }
}

struct SettingSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var valueFormatter: ((Double) -> String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Spacer()

                if let formatter = valueFormatter {
                    Text(formatter(value))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 12) {
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景轨道
                        Rectangle()
                            .fill(Color(white: 0.3))
                            .frame(height: 4)
                            .cornerRadius(2)

                        // 已填充部分
                        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                        Rectangle()
                            .fill(Color(red: 1.0, green: 0.3, blue: 0.4))
                            .frame(width: max(0, geometry.size.width * progress), height: 4)
                            .cornerRadius(2)

                        // 滑块
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: max(0, min(geometry.size.width - 20, geometry.size.width * progress - 10)))
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let progress = min(max(0, gesture.location.x / geometry.size.width), 1)
                                value = range.lowerBound + progress * (range.upperBound - range.lowerBound)
                            }
                    )
                }
                .frame(height: 20)
            }
        }
        .padding(.horizontal)
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)

                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 40, height: 40)
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TeleprompterSettingsView(script: Script(content: "示例台词内容\n第二行\n第三行"))
}

// MARK: - Player Layer View
struct PlayerLayerView: UIViewRepresentable {
    let playerLayer: AVPlayerLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.addSublayer(playerLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        playerLayer.frame = uiView.bounds
    }
}

// MARK: - PiP Teleprompter Controller
class PiPTeleprompterController: NSObject, ObservableObject {
    @Published var isActive = false
    @Published var isPiPSupported = AVPictureInPictureController.isPictureInPictureSupported()
    @Published var isGeneratingVideo = false
    @Published var errorMessage: String?
    @Published var playerLayer: AVPlayerLayer?

    private var pipController: AVPictureInPictureController?
    private var player: AVPlayer?
    private var videoRenderer: TeleprompterVideoRenderer?
    private var sceneObserver: NSObjectProtocol?
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3

    override init() {
        super.init()
        setupAudioSession()
        setupSceneObserver()
    }

    private func setupSceneObserver() {
        // 监听应用进入前台/后台事件
        sceneObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let scene = notification.object as? UIWindowScene {
                print("📱 Scene 已激活，状态: \(scene.activationState.rawValue)")
            } else {
                print("📱 Scene 已激活 (前台活跃状态)")
            }
        }
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 使用 playback 类别，支持后台播放
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func startPiP(script: Script, settings: TeleprompterSettings) {
        guard isPiPSupported else {
            print("PiP is not supported")
            errorMessage = "此设备不支持画中画功能"
            return
        }

        // 先清理之前的资源（如果有的话）
        if pipController != nil || player != nil {
            print("检测到现有资源，先清理...")
            cleanupResources()

            // 等待一小段时间确保资源完全释放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.actuallyStartPiP(script: script, settings: settings)
            }
            return
        }

        actuallyStartPiP(script: script, settings: settings)
    }

    private func actuallyStartPiP(script: Script, settings: TeleprompterSettings) {
        isGeneratingVideo = true
        errorMessage = nil

        // 在后台线程生成视频
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            print("开始生成视频...")

            // 创建视频渲染器
            let videoRenderer = TeleprompterVideoRenderer(script: script, settings: settings)
            self.videoRenderer = videoRenderer

            // 创建播放器
            guard let videoURL = videoRenderer.createVideoFile() else {
                DispatchQueue.main.async {
                    self.isGeneratingVideo = false
                    self.errorMessage = "视频生成失败"
                    print("视频生成失败")
                }
                return
            }

            print("视频已生成: \(videoURL)")

            DispatchQueue.main.async {
                self.isGeneratingVideo = false

                let playerItem = AVPlayerItem(url: videoURL)
                let player = AVPlayer(playerItem: playerItem)

                // 不设置循环播放，播放完就停止
                // 监听播放结束通知
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { [weak self] _ in
                    print("视频播放完成，停留在最后一帧")
                    // 播放完成后停留在最后一帧，不做任何操作
                }

                self.player = player

                // 先播放一下，确保视频准备好
                player.play()
                player.pause()

                // 创建播放器层
                let layer = AVPlayerLayer(player: player)
                layer.videoGravity = .resizeAspect
                // 横屏长条形尺寸
                layer.frame = CGRect(x: 0, y: 0, width: 1920, height: 960)

                // 先设置 playerLayer，触发视图更新
                self.playerLayer = layer

                // 等待视图更新完成
                DispatchQueue.main.async {
                    // 再等一个 RunLoop，确保 playerLayer 被添加到视图
                    DispatchQueue.main.async {
                        self.setupPiPController(with: layer, player: player)
                    }
                }
            }
        }
    }

    private func setupPiPController(with layer: AVPlayerLayer, player: AVPlayer) {
        // 创建 PiP 控制器（必须在 playerLayer 被添加到视图层级后创建）
        if let pipController = AVPictureInPictureController(playerLayer: layer) {
            print("画中画控制器创建成功")
            pipController.delegate = self
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            self.pipController = pipController

            print("是否支持画中画: \(AVPictureInPictureController.isPictureInPictureSupported())")

            // 等待 playerLayer 完全渲染
            // 延迟 0.5 秒给足够的时间让 playerLayer 准备好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.attemptStartPiP()
            }
        } else {
            self.errorMessage = "无法创建画中画控制器"
            print("无法创建画中画控制器")
        }
    }

    private func attemptStartPiP(retryCount: Int = 0) {
        guard let pipController = pipController else {
            print("❌ 画中画控制器未初始化")
            errorMessage = "画中画控制器未初始化"
            return
        }

        guard let player = player else {
            print("❌ 播放器未初始化")
            errorMessage = "播放器未初始化"
            return
        }

        // 确保播放器有内容
        if player.currentItem?.status != .readyToPlay {
            print("⏳ 播放器还未准备好，状态: \(player.currentItem?.status.rawValue ?? -1)")
            if retryCount < 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.attemptStartPiP(retryCount: retryCount + 1)
                }
            } else {
                errorMessage = "播放器加载超时"
            }
            return
        }

        print("\n=== 尝试启动画中画 (第 \(retryCount + 1) 次) ===")
        print("画中画是否可用: \(pipController.isPictureInPicturePossible)")
        print("播放器是否在播放: \(player.rate > 0)")
        print("播放器时间: \(player.currentTime().seconds)")
        print("播放器状态: \(player.currentItem?.status.rawValue ?? -1)")

        // 检查应用是否在前台活跃状态
        let scenes = UIApplication.shared.connectedScenes
        print("当前连接的场景数: \(scenes.count)")

        // 打印所有场景的状态以便调试
        var allSceneStates: [String] = []
        for (index, scene) in scenes.enumerated() {
            if let windowScene = scene as? UIWindowScene {
                let state = windowScene.activationState
                let stateName: String
                switch state {
                case .foregroundActive: stateName = "foregroundActive(1)"
                case .foregroundInactive: stateName = "foregroundInactive(0)"
                case .background: stateName = "background(2)"
                case .unattached: stateName = "unattached(-1)"
                @unknown default: stateName = "unknown(\(state.rawValue))"
                }
                allSceneStates.append("Scene\(index)=\(stateName)")
                print("Scene \(index): 状态 = \(stateName)")
            }
        }

        // 直接使用第一个场景（简化逻辑）
        guard let windowScene = scenes.first as? UIWindowScene else {
            print("❌ 未找到任何 WindowScene")
            errorMessage = "应用窗口未就绪"
            return
        }

        // 检查场景状态（仅用于日志）
        let state = windowScene.activationState
        print("使用第一个场景，状态: \(state == .foregroundActive ? "foregroundActive" : state == .foregroundInactive ? "foregroundInactive" : "其他")")

        // 如果不是 foregroundActive，重试
        if state != .foregroundActive {
            print("❌ 场景不是 foregroundActive，需要重试")

            if retryCount < 5 {
                print("⏳ 将在 0.5 秒后进行第 \(retryCount + 2) 次尝试")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.attemptStartPiP(retryCount: retryCount + 1)
                }
            } else {
                print("❌ 已重试 5 次，应用始终不在前台活跃状态")
                errorMessage = "应用未在前台活跃状态，请重试"
            }
            return
        }

        print("✅ 场景是 foregroundActive，准备启动画中画")

        // 确保画中画可用
        if !pipController.isPictureInPicturePossible {
            print("❌ 画中画功能暂时不可用")

            // 如果画中画暂时不可用，也尝试重试
            if retryCount < 5 {
                print("⏳ 将在 0.5 秒后进行第 \(retryCount + 2) 次尝试")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.attemptStartPiP(retryCount: retryCount + 1)
                }
            } else {
                print("❌ 已重试 5 次，画中画仍不可用")
                errorMessage = "画中画暂时不可用，请稍后重试"
            }
            return  // 重要：立即返回，不继续执行
        }

        // 所有条件都满足，启动画中画
        print("✅ 所有条件满足，启动画中画")
        pipController.startPictureInPicture()
        print("✅ 已调用 startPictureInPicture()")
    }

    private func cleanupResources() {
        print("清理资源...")

        // 停止倒计时定时器
        countdownTimer?.invalidate()
        countdownTimer = nil

        // 停止播放器
        player?.pause()

        // 停止画中画（如果正在运行）
        if let pip = pipController, pip.isPictureInPictureActive {
            pip.stopPictureInPicture()
        }

        videoRenderer?.stop()

        // 清理所有资源
        pipController = nil
        player = nil
        playerLayer = nil
        videoRenderer = nil

        print("资源清理完成")
    }

    func stopPiP() {
        print("停止画中画...")
        cleanupResources()

        isActive = false
        errorMessage = nil
        print("画中画已停止")
    }

    deinit {
        if let observer = sceneObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        stopPiP()
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension PiPTeleprompterController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("PiP will start")
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("PiP did start")
        DispatchQueue.main.async {
            self.isActive = true

            // 启动倒计时
            self.startCountdown()
        }
    }

    private func startCountdown() {
        countdownValue = 3
        videoRenderer?.showCountdown(countdownValue)

        // 创建定时器每秒更新倒计时
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.countdownValue -= 1

            if self.countdownValue > 0 {
                // 更新倒计时显示
                self.videoRenderer?.showCountdown(self.countdownValue)
            } else {
                // 倒计时结束
                timer.invalidate()
                self.countdownTimer = nil
                self.videoRenderer?.hideCountdown()

                print("▶️ 开始播放")
                self.player?.play()
            }
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("PiP did stop")
        DispatchQueue.main.async {
            self.isActive = false
        }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("❌ PiP failed to start: \(error)")
        print("错误详情: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("错误域: \(nsError.domain)")
            print("错误代码: \(nsError.code)")
            print("错误信息: \(nsError.userInfo)")
        }
        DispatchQueue.main.async {
            self.isActive = false
            self.errorMessage = "画中画启动失败: \(error.localizedDescription)"
        }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // 用户点击 PiP 窗口时恢复界面
        completionHandler(true)
    }
}

// MARK: - Teleprompter Video Renderer
class TeleprompterVideoRenderer {
    private let script: Script
    private let settings: TeleprompterSettings

    // 画中画尺寸：横屏长条形（宽度填满，高度约为屏幕的1/2）
    // 使用 1920x960 (2:1宽高比)
    private let videoSize = CGSize(width: 1920, height: 960)
    private let fps: Double = 30

    // 倒计时状态
    private var isShowingCountdown = false
    private var currentCountdown = 0

    // 预处理后的行（已经按宽度拆分）
    private var wrappedLines: [String] = []

    init(script: Script, settings: TeleprompterSettings) {
        self.script = script
        self.settings = settings

        // 在初始化时预先将内容按宽度拆分成多行
        self.wrappedLines = self.wrapContentToLines()
    }

    func showCountdown(_ value: Int) {
        isShowingCountdown = true
        currentCountdown = value
    }

    func hideCountdown() {
        isShowingCountdown = false
    }

    // 将脚本内容按字号和宽度拆分成多行
    private func wrapContentToLines() -> [String] {
        let fontSize = settings.fontSize * 6.0
        let padding: CGFloat = 60
        let maxWidth = videoSize.width - padding * 2

        let font = CTFontCreateWithName("PingFang SC" as CFString, fontSize, nil)
        let originalLines = script.content.components(separatedBy: .newlines)

        var result: [String] = []

        // 添加前置空行（让第一行从高亮区域开始）
        // 只需要 1 行，让第一行直接出现在高亮位置
        result.append(" ")

        for line in originalLines {
            guard !line.isEmpty else { continue }

            // 检查这一行是否需要拆分
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.cgColor
            ]

            let attributedString = NSAttributedString(string: line, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

            // 使用临时路径获取拆分后的行
            let path = CGPath(rect: CGRect(x: 0, y: 0, width: maxWidth, height: 10000), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attributedString.length), path, nil)

            // 获取所有拆分后的行
            let lines = CTFrameGetLines(frame) as! [CTLine]

            if lines.isEmpty {
                result.append(line)
                continue
            }

            // 提取每一行的文本
            for ctLine in lines {
                let lineRange = CTLineGetStringRange(ctLine)
                let start = String.Index(utf16Offset: lineRange.location, in: line)
                let end = String.Index(utf16Offset: lineRange.location + lineRange.length, in: line)
                let substring = String(line[start..<end]).trimmingCharacters(in: .whitespaces)

                if !substring.isEmpty {
                    result.append(substring)
                }
            }
        }

        // 添加后置空行（让最后几行停留在可见区域）
        // 视频播放完会停在最后一帧，所以添加足够的空行让最后几行清晰可见
        // 高亮区域在 40% 位置，下方还有 60% 空间，大约需要 3-4 行
        for _ in 0..<4 {
            result.append(" ")  // 空格占位
        }

        print("原始行数: \(originalLines.filter { !$0.isEmpty }.count), 拆分后行数: \(result.count)（含前后缓冲行）")
        return result
    }

    func createVideoFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("teleprompter_\(UUID().uuidString).mp4")

        // 删除已存在的文件
        try? FileManager.default.removeItem(at: videoURL)

        // 根据内容长度和滚动速度计算视频时长
        // 总行数 × 每行滚动秒数 = 总时长
        let totalLines = wrappedLines.count
        let duration: Double = Double(totalLines) * settings.scrollSpeed

        // 限制最短 10 秒，最长 300 秒（5分钟）
        let clampedDuration = min(max(duration, 10.0), 300.0)
        let totalFrames = Int(clampedDuration * fps)

        print("开始创建视频，共 \(totalFrames) 帧")
        print("视频尺寸: \(videoSize)")
        print("原始脚本行数: \(script.content.components(separatedBy: .newlines).count)")
        print("拆分后行数: \(wrappedLines.count)")
        print("计算时长: \(totalLines) 行 × \(settings.scrollSpeed) 秒/行 = \(duration) 秒")
        print("实际时长: \(clampedDuration) 秒")
        print("字号: \(settings.fontSize)")
        print("文字颜色: \(settings.textColor)")

        do {
            // 创建 AssetWriter
            let writer = try AVAssetWriter(outputURL: videoURL, fileType: .mp4)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoSize.width,
                AVVideoHeightKey: videoSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 1_500_000,
                    AVVideoMaxKeyFrameIntervalKey: 30
                ]
            ]

            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writerInput.expectsMediaDataInRealTime = false

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: writerInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                    kCVPixelBufferWidthKey as String: videoSize.width,
                    kCVPixelBufferHeightKey as String: videoSize.height
                ]
            )

            guard writer.canAdd(writerInput) else {
                print("无法添加 writer input")
                return nil
            }

            writer.add(writerInput)

            guard writer.startWriting() else {
                print("启动写入失败: \(writer.error?.localizedDescription ?? "未知错误")")
                return nil
            }

            writer.startSession(atSourceTime: .zero)

            // 生成视频帧
            var frameCount = 0
            var currentOffset: CGFloat = 0

            // 使用放大后的字号和滚动速度（与 drawText 保持一致）
            let fontSize = settings.fontSize * 6.0
            let lineSpacing: CGFloat = 40
            // 使用平均行高来计算滚动速度
            // scrollSpeed 是每行滚动的秒数，所以每秒移动 averageLineHeight/scrollSpeed 像素
            let averageLineHeight = fontSize + lineSpacing
            let pointsPerSecond = averageLineHeight / CGFloat(settings.scrollSpeed)
            let speed = pointsPerSecond / CGFloat(fps)

            print("滚动配置: 原始字号=\(settings.fontSize), 放大后字号=\(fontSize), 平均行高=\(averageLineHeight), 滚动速度=\(settings.scrollSpeed)秒/行, 每帧移动=\(speed)像素")

            print("开始并发生成视频帧...")

            // 使用并发队列批量生成帧
            let batchSize = 30  // 每批处理30帧
            let totalBatches = (totalFrames + batchSize - 1) / batchSize

            for batchIndex in 0..<totalBatches {
                let batchStart = batchIndex * batchSize
                let batchEnd = min(batchStart + batchSize, totalFrames)
                let batchCount = batchEnd - batchStart

                // 并发生成这一批的所有帧
                var batchBuffers: [(CVPixelBuffer, CMTime)] = []
                let queue = DispatchQueue(label: "video.frame.generation", attributes: .concurrent)
                let group = DispatchGroup()
                let lock = NSLock()

                for i in 0..<batchCount {
                    let frameIndex = batchStart + i
                    let offset = CGFloat(frameIndex) * speed

                    group.enter()
                    queue.async {
                        if let buffer = self.createPixelBuffer(offset: offset) {
                            let presentationTime = CMTime(value: Int64(frameIndex), timescale: Int32(self.fps))
                            lock.lock()
                            batchBuffers.append((buffer, presentationTime))
                            lock.unlock()
                        }
                        group.leave()
                    }
                }

                // 等待这一批全部生成完成
                group.wait()

                // 按顺序写入这一批帧
                batchBuffers.sort { $0.1.value < $1.1.value }

                for (buffer, time) in batchBuffers {
                    while !writerInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.01)
                    }
                    adaptor.append(buffer, withPresentationTime: time)
                    frameCount += 1
                }

                if batchIndex % 10 == 0 || batchIndex == totalBatches - 1 {
                    print("已生成 \(frameCount)/\(totalFrames) 帧 (批次 \(batchIndex + 1)/\(totalBatches))")
                }
            }

            writerInput.markAsFinished()

            let semaphore = DispatchSemaphore(value: 0)
            writer.finishWriting {
                print("视频写入完成: \(writer.status.rawValue)")
                if let error = writer.error {
                    print("写入错误: \(error.localizedDescription)")
                }
                semaphore.signal()
            }

            semaphore.wait()

            if writer.status == .completed {
                print("视频创建成功: \(videoURL)")
                return videoURL
            } else {
                print("视频创建失败: \(writer.error?.localizedDescription ?? "未知错误")")
                return nil
            }
        } catch {
            print("创建视频时出错: \(error.localizedDescription)")
            return nil
        }
    }

    private func createPixelBuffer(offset: CGFloat) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(videoSize.width),
            Int(videoSize.height),
            kCVPixelFormatType_32ARGB,
            options,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(videoSize.width),
            height: Int(videoSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        // 绘制背景
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: videoSize))

        // 绘制文本
        drawText(in: context, offset: offset)

        // 如果正在显示倒计时，绘制倒计时覆盖层
        if isShowingCountdown {
            drawCountdown(in: context)
        }

        return buffer
    }

    private func drawCountdown(in context: CGContext) {
        // 绘制半透明黑色背景
        context.saveGState()
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context.fill(CGRect(origin: .zero, size: videoSize))

        // 绘制倒计时数字
        let countdownText = "\(currentCountdown)"
        let fontSize: CGFloat = 400  // 超大字号
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.cgColor
        ]

        let attributedString = NSAttributedString(string: countdownText, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)

        // 计算文本尺寸以居中显示
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

        let x = (videoSize.width - bounds.width) / 2 - bounds.minX
        let y = (videoSize.height - bounds.height) / 2 - bounds.minY

        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)

        context.restoreGState()
    }

    private func drawText(in context: CGContext, offset: CGFloat) {
        // 使用预处理后的行（已经按宽度拆分，每行都不会太长）
        let lines = wrappedLines

        // 横屏画中画，大幅放大字号以确保在画中画窗口中清晰可读
        // 视频分辨率 1920x960，画中画会缩小显示，所以需要放大 6 倍字号
        let fontSize = settings.fontSize * 6.0
        let lineSpacing: CGFloat = 60  // 行间距
        let padding: CGFloat = 60

        // 不需要翻转坐标系，直接在 CGContext 中绘制
        context.saveGState()

        // 创建字体
        let font = CTFontCreateWithName("PingFang SC" as CFString, fontSize, nil)

        // 计算单行文本的标准高度
        let sampleAttributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        let sampleString = NSAttributedString(string: "测试Ag", attributes: sampleAttributes)
        let sampleLine = CTLineCreateWithAttributedString(sampleString)
        let sampleBounds = CTLineGetBoundsWithOptions(sampleLine, .useOpticalBounds)
        let lineHeight = sampleBounds.height + lineSpacing

        // 计算总内容高度
        let totalContentHeight = CGFloat(lines.count) * lineHeight

        // 使用模运算实现无缝循环
        let loopedOffset = offset.truncatingRemainder(dividingBy: totalContentHeight)

        // 高亮区域：屏幕中央偏上位置（从顶部算起 40%）
        let highlightY = videoSize.height * 0.4

        for (index, lineText) in lines.enumerated() {
            // 计算文字位置（从上往下滚动，下一句在下面）
            let yPosition = CGFloat(index) * lineHeight
            var y = highlightY - yPosition + loopedOffset

            // 实现无缝循环：如果文字滚出顶部，在底部重复绘制
            if y < -lineHeight {
                y += totalContentHeight
            }
            // 如果文字滚出底部，在顶部重复绘制
            if y > videoSize.height + lineHeight {
                y -= totalContentHeight
            }

            // 跳过屏幕外的文本
            guard y > -lineHeight && y < videoSize.height + lineHeight else { continue }

            // 计算距离高亮区域的距离，实现逐行高亮效果
            let distanceFromHighlight = abs(y - highlightY)
            let isHighlighted = distanceFromHighlight < lineHeight * 0.5

            // 高亮行使用用户配置的颜色，其他行使用半透明的颜色
            let color: UIColor
            if isHighlighted {
                color = UIColor(settings.textColor)
            } else {
                // 其他行使用降低亮度的颜色
                color = UIColor(settings.textColor).withAlphaComponent(0.4)
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color.cgColor
            ]

            let attributedString = NSAttributedString(string: lineText, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributedString)

            // 计算居中对齐（可选）或左对齐
            let lineBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
            let x = padding // 左对齐

            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(line, context)
        }

        // 只在第一帧时打印调试信息
        if offset < 1.0 {
            print("第一帧绘制: 字号=\(fontSize), 行高=\(lineHeight), 总内容高度=\(totalContentHeight)")
            print("绘制了 \(lines.count) 行文字（已预先拆分）")
        }

        context.restoreGState()
    }

    func stop() {
        // 清理资源
    }
}
