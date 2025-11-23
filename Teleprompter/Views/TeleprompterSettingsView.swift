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
                                            isSelected: areColorsEqual(settings.textColor, color),
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
                    // 状态显示
                    if pipController.isGeneratingVideo {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color(red: 1.0, green: 0.3, blue: 0.4))

                            Text("正在生成画中画视频...")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 20)
                    } else if pipController.isActive {
                        VStack(spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                Text("画中画已启动")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }

                            Text("现在可以切换到相机 App 录制视频")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.vertical, 20)
                    } else if let errorMessage = pipController.errorMessage {
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
                                    Text("生成中...")
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
                let player = AVQueuePlayer(playerItem: playerItem)

                // 设置循环播放
                let looper = AVPlayerLooper(player: player, templateItem: playerItem)
                objc_setAssociatedObject(player, "looper", looper, .OBJC_ASSOCIATION_RETAIN)

                self.player = player

                // 创建播放器层
                let layer = AVPlayerLayer(player: player)
                layer.videoGravity = .resizeAspect
                // 横屏长条形尺寸
                layer.frame = CGRect(x: 0, y: 0, width: 1920, height: 960)
                self.playerLayer = layer

                // 创建 PiP 控制器（必须在 playerLayer 创建后立即创建）
                if let pipController = AVPictureInPictureController(playerLayer: layer) {
                    print("画中画控制器创建成功")
                    pipController.delegate = self
                    pipController.canStartPictureInPictureAutomaticallyFromInline = true
                    self.pipController = pipController

                    print("是否支持画中画: \(AVPictureInPictureController.isPictureInPictureSupported())")

                    // 启动播放
                    player.play()

                    // 等待下一个 RunLoop 周期，确保 playerLayer 已被添加到视图层级
                    DispatchQueue.main.async {
                        // 等待 playerLayer 完全渲染，同时确保 Scene 处于活跃状态
                        // 增加延迟以避免 Scene 状态问题（从 foregroundInactive 变为 foregroundActive）
                        // 延迟 1.5 秒给足够的时间让场景激活
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.attemptStartPiP()
                        }
                    }
                } else {
                    self.errorMessage = "无法创建画中画控制器"
                    print("无法创建画中画控制器")
                }
            }
        }
    }

    private func attemptStartPiP(retryCount: Int = 0) {
        guard let pipController = pipController else {
            print("❌ 画中画控制器未初始化")
            errorMessage = "画中画控制器未初始化"
            return
        }

        print("\n=== 尝试启动画中画 (第 \(retryCount + 1) 次) ===")
        print("画中画是否可用: \(pipController.isPictureInPicturePossible)")
        print("播放器是否在播放: \(player?.rate ?? 0 > 0)")
        print("播放器时间: \(player?.currentTime().seconds ?? 0)")

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

    func stopPiP() {
        print("停止画中画...")
        pipController?.stopPictureInPicture()
        player?.pause()
        videoRenderer?.stop()

        // 清理资源，为下次启动做准备
        pipController = nil
        player = nil
        playerLayer = nil
        videoRenderer = nil

        isActive = false
        errorMessage = nil
        print("画中画已停止并清理资源")
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

    init(script: Script, settings: TeleprompterSettings) {
        self.script = script
        self.settings = settings
    }

    func createVideoFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("teleprompter_\(UUID().uuidString).mp4")

        // 删除已存在的文件
        try? FileManager.default.removeItem(at: videoURL)

        // 创建 30 秒的循环视频
        let duration: Double = 30.0
        let totalFrames = Int(duration * fps)

        print("开始创建视频，共 \(totalFrames) 帧")
        print("视频尺寸: \(videoSize)")
        print("脚本内容行数: \(script.content.components(separatedBy: .newlines).count)")
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
            let fontSize = settings.fontSize * 3.5
            let lineHeight = fontSize + 20
            // scrollSpeed 是每行滚动的秒数，所以每秒移动 lineHeight/scrollSpeed 像素
            let pointsPerSecond = lineHeight / CGFloat(settings.scrollSpeed)
            let speed = pointsPerSecond / CGFloat(fps)

            print("滚动配置: 原始字号=\(settings.fontSize), 放大后字号=\(fontSize), 行高=\(lineHeight), 滚动速度=\(settings.scrollSpeed)秒/行, 每帧移动=\(speed)像素")

            print("开始写入视频帧...")

            while frameCount < totalFrames {
                if writerInput.isReadyForMoreMediaData {
                    let presentationTime = CMTime(value: Int64(frameCount), timescale: Int32(fps))

                    if let pixelBuffer = createPixelBuffer(offset: currentOffset) {
                        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    } else {
                        print("创建像素缓冲区失败: frame \(frameCount)")
                    }

                    currentOffset += speed
                    frameCount += 1

                    if frameCount % 100 == 0 {
                        print("已生成 \(frameCount)/\(totalFrames) 帧")
                    }
                } else {
                    Thread.sleep(forTimeInterval: 0.01)
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

        return buffer
    }

    private func drawText(in context: CGContext, offset: CGFloat) {
        let lines = script.content.components(separatedBy: .newlines)

        // 横屏画中画，大幅放大字号以确保在画中画窗口中清晰可读
        // 视频分辨率 1920x960 很大，放大 3.5 倍字号
        let fontSize = settings.fontSize * 3.5
        let lineHeight = fontSize + 20

        // 不需要翻转坐标系，直接在 CGContext 中绘制
        context.saveGState()

        // 计算总内容高度以实现循环滚动
        let totalContentHeight = CGFloat(lines.filter { !$0.isEmpty }.count) * lineHeight
        // 使用模运算实现无缝循环
        let loopedOffset = offset.truncatingRemainder(dividingBy: totalContentHeight)

        // 高亮区域：屏幕中央偏上位置（从顶部算起 40%）
        let highlightY = videoSize.height * 0.4

        var drawnCount = 0

        for (index, line) in lines.enumerated() {
            guard !line.isEmpty else { continue }

            // 计算文字位置（从底部向上滚动）
            // y 坐标从屏幕底部开始，向上滚动
            var y = videoSize.height - (CGFloat(index) * lineHeight - loopedOffset + videoSize.height * 0.1)

            // 实现无缝循环：如果文字滚出底部，在顶部重复绘制
            if y > videoSize.height + lineHeight {
                y -= totalContentHeight
            }

            // 跳过屏幕外的文本
            guard y > -lineHeight && y < videoSize.height + lineHeight else { continue }

            // 计算距离高亮区域的距离，实现逐行高亮效果
            let distanceFromHighlight = abs(y - highlightY)
            let isHighlighted = distanceFromHighlight < lineHeight * 0.6

            // 高亮行使用用户配置的颜色，其他行使用半透明的颜色
            let color: UIColor
            if isHighlighted {
                color = UIColor(settings.textColor)
            } else {
                // 其他行使用降低亮度的颜色
                color = UIColor(settings.textColor).withAlphaComponent(0.4)
            }

            // 使用 CoreText 直接在 CGContext 中绘制文字（正确方向）
            let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color.cgColor
            ]

            let attributedString = NSAttributedString(string: line, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributedString)

            // 计算文字宽度以居中显示
            let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
            let padding: CGFloat = 40
            let x: CGFloat
            if lineWidth > Double(videoSize.width - padding * 2) {
                x = padding
            } else {
                x = (videoSize.width - CGFloat(lineWidth)) / 2
            }

            // 设置文字绘制位置（y 坐标需要从底部算起）
            context.textPosition = CGPoint(x: x, y: y)

            // 绘制文字
            CTLineDraw(line, context)
            drawnCount += 1
        }

        // 只在第一帧时打印调试信息
        if offset < 1.0 {
            print("第一帧绘制: 字号=\(fontSize), 行高=\(lineHeight), 总内容高度=\(totalContentHeight)")
            print("绘制了 \(drawnCount) 行文字，总行数: \(lines.filter { !$0.isEmpty }.count)")
            print("文字颜色: \(settings.textColor)")
        }

        context.restoreGState()
    }

    func stop() {
        // 清理资源
    }
}
