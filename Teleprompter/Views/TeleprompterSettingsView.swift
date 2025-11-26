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
                // 注意：playerLayer 需要有合理的尺寸才能启动画中画
                if pipController.playerLayer != nil {
                    PlayerLayerView(playerLayer: pipController.playerLayer!)
                        .frame(width: 100, height: 100)
                        .opacity(0.001)
                        .allowsHitTesting(false)
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

                        // 文字旋转 - 暂时注释掉
                        // HStack {
                        //     Text("文字旋转")
                        //         .font(.system(size: 16))
                        //         .foregroundColor(.white)
                        //     Spacer()
                        //     Button(action: {
                        //         rotation = (rotation + 90) % 360
                        //     }) {
                        //         HStack(spacing: 4) {
                        //             Image(systemName: "rectangle.portrait.rotate")
                        //             Text("\(rotation)°")
                        //         }
                        //         .font(.system(size: 14))
                        //         .foregroundColor(.white)
                        //         .padding(.horizontal, 12)
                        //         .padding(.vertical, 8)
                        //         .background(Color(white: 0.2))
                        //         .cornerRadius(8)
                        //     }
                        // }
                        // .padding(.horizontal)

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
                    // 状态显示 - 显示错误信息或使用提示
                    if let errorMessage = pipController.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    } else if pipController.isActive {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("悬浮提词已启动")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Text("可以切换到其他 App 使用\n打开相机时提词会暂停，关闭相机后自动恢复")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
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
        print("📐 PlayerLayerView makeUIView - playerLayer.frame: \(playerLayer.frame)")
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 确保 playerLayer 的 frame 不是零
        // 注意：不要使用 uiView.bounds，因为它可能是 (0,0,0,0)
        print("📐 PlayerLayerView updateUIView - 当前 playerLayer.frame: \(playerLayer.frame), uiView.bounds: \(uiView.bounds)")

        // 如果 frame 是零，设置一个合理的尺寸
        if playerLayer.frame.size.width == 0 || playerLayer.frame.size.height == 0 {
            playerLayer.frame = CGRect(x: 0, y: 0, width: 1920, height: 960)
            print("📐 已重置 playerLayer.frame 为: \(playerLayer.frame)")
        }
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
    private var sceneActivationObserver: NSObjectProtocol?
    private var audioInterruptionObserver: NSObjectProtocol?

    override init() {
        super.init()
        print("🔧 PiPTeleprompterController 初始化")
        setupAudioInterruptionObserver()
    }

    // 音频会话配置：使用 .playback + .mixWithOthers
    // 这样画中画窗口不会被相机关闭，只是播放会暂停
    private func setupAudioSessionForPiP() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // .playback: 支持画中画
            // .mixWithOthers: 画中画窗口与相机共存（但播放会被暂停）
            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers]
            )
            try audioSession.setActive(true)
            print("✅ 音频会话配置：playback + mixWithOthers")
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

    // 监听音频会话中断（相机开启/关闭时会触发）
    private func setupAudioInterruptionObserver() {
        audioInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }

            switch type {
            case .began:
                print("🎵 音频会话被中断（相机可能已开启）")
                // 中断开始时，系统会自动暂停播放
                // 我们可以在这里显示提示信息
                DispatchQueue.main.async {
                    self.errorMessage = "⚠️ 相机使用中，提词已暂停\n关闭相机后将自动恢复"
                }

            case .ended:
                print("🎵 音频会话中断结束")
                // 清除错误信息
                DispatchQueue.main.async {
                    self.errorMessage = nil
                }

                // 检查是否应该恢复播放
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        // 延迟一下再恢复，确保音频会话已准备好
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.resumePlayback()
                        }
                    }
                }

            @unknown default:
                break
            }
        }
    }

    // 恢复播放
    private func resumePlayback() {
        guard let player = player, player.rate == 0, isActive else {
            return
        }

        do {
            // 重新激活音频会话
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            player.play()
            print("▶️ 已自动恢复播放")
        } catch {
            print("⚠️ 恢复播放失败: \(error)")
        }
    }

    // 监听场景激活，当用户点击画中画窗口时也尝试恢复播放
    private func setupSceneActivationObserver() {
        sceneActivationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            // 延迟一下，让场景完全激活
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.resumePlayback()
            }
        }
    }


    func startPiP(script: Script, settings: TeleprompterSettings) {
        guard isPiPSupported else {
            print("PiP is not supported")
            errorMessage = "此设备不支持画中画功能"
            return
        }

        // 清除错误信息
        errorMessage = nil

        // 配置音频会话
        setupAudioSessionForPiP()

        // 先清理之前的资源
        if pipController != nil || player != nil {
            print("检测到现有资源，先清理...")
            cleanupResources()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.actuallyStartPiP(script: script, settings: settings)
            }
            return
        }

        // 使用视频方式启动 PiP
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

                // 静音播放，避免与其他 App 的音频冲突
                player.isMuted = true
                player.volume = 0.0

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

                // 创建播放器层
                let layer = AVPlayerLayer(player: player)
                layer.videoGravity = .resizeAspect
                // 横屏长条形尺寸
                layer.frame = CGRect(x: 0, y: 0, width: 1920, height: 960)

                // 先设置 playerLayer，触发视图更新
                self.playerLayer = layer

                // 关键：立即开始播放！
                // PiP 要求播放器处于播放状态
                // 播放器是静音的，所以不会有声音
                player.play()
                print("▶️ 播放器开始播放（静音）")

                // 等待 playerLayer 完全准备好
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.setupPiPController(with: layer, player: player)
                }
            }
        }
    }

    private func setupPiPController(with layer: AVPlayerLayer, player: AVPlayer) {
        // 创建 PiP 控制器（必须在 playerLayer 被添加到视图层级后创建）
        if let pipController = AVPictureInPictureController(playerLayer: layer) {
            print("✅ 画中画控制器创建成功")
            pipController.delegate = self
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            self.pipController = pipController

            print("✅ 是否支持画中画: \(AVPictureInPictureController.isPictureInPictureSupported())")

            // 等待 playerLayer 被添加到视图层级
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.attemptStartPiP()
            }
        } else {
            self.errorMessage = "无法创建画中画控制器"
            print("❌ 无法创建画中画控制器")
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
                print("❌ 播放器加载超时")
            }
            return
        }

        print("\n=== 尝试启动画中画 (第 \(retryCount + 1) 次) ===")
        print("📊 画中画是否可用: \(pipController.isPictureInPicturePossible)")
        print("📊 播放器状态: \(player.currentItem?.status.rawValue ?? -1) (1=readyToPlay)")
        print("📊 PlayerLayer frame: \(pipController.playerLayer.frame)")

        // 检查应用场景状态
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene else {
            print("❌ 未找到任何 WindowScene")
            errorMessage = "应用窗口未就绪"
            return
        }

        let state = windowScene.activationState
        print("📊 场景状态: \(state == .foregroundActive ? "✅ foregroundActive" : "❌ \(state.rawValue)")")

        // 如果不是 foregroundActive，重试
        if state != .foregroundActive {
            if retryCount < 5 {
                print("⏳ 场景未激活，将在 0.5 秒后重试")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.attemptStartPiP(retryCount: retryCount + 1)
                }
            } else {
                print("❌ 场景始终未激活")
                errorMessage = "应用未在前台活跃状态"
            }
            return
        }

        // 确保画中画可用
        if !pipController.isPictureInPicturePossible {
            print("❌ isPictureInPicturePossible = false")

            if retryCount < 5 {
                print("⏳ 将在 0.5 秒后重试 (可能 playerLayer 还未完全加载)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.attemptStartPiP(retryCount: retryCount + 1)
                }
            } else {
                print("❌ 画中画仍不可用，可能原因：")
                print("   1. playerLayer 未正确添加到视图层级")
                print("   2. playerLayer 的 frame 太小")
                print("   3. 设备不支持画中画（但 isPictureInPictureSupported=true）")
                errorMessage = "画中画启动失败，请重新尝试"
            }
            return
        }

        // 所有条件都满足，启动画中画
        print("✅ 所有条件满足，启动画中画！")
        pipController.startPictureInPicture()
        print("✅ 已调用 startPictureInPicture()")
    }

    private func cleanupResources() {
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
    }

    func stopPiP() {
        cleanupResources()
        isActive = false
        errorMessage = nil
    }

    deinit {
        // 清理观察者
        if let observer = sceneActivationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = audioInterruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // 清理资源
        stopPiP()
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension PiPTeleprompterController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("PiP will start")
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isActive = true
            print("✅ 画中画已启动")
            print("ℹ️ 提示：打开相机时播放会暂停，关闭相机后会自动恢复")

            // 启动后设置场景监听
            self.setupSceneActivationObserver()
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("🛑 PiP did stop (用户关闭或系统停止)")
        DispatchQueue.main.async {
            self.isActive = false
            // 不需要自动重启，如果用户关闭了 PiP，应该尊重用户的选择
            // 如果是系统停止的（比如另一个 App 也启动了 PiP），用户可以手动重启
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

    // 保存生成的视频文件 URL，用于清理
    private var videoURL: URL?

    init(script: Script, settings: TeleprompterSettings) {
        self.script = script
        self.settings = settings

        // 在初始化时预先将内容按宽度拆分成多行
        self.wrappedLines = self.wrapContentToLines()

        // 清理旧的临时视频文件
        cleanupOldVideoFiles()
    }

    // 清理所有旧的提词器临时视频文件
    private func cleanupOldVideoFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            let teleprompterFiles = files.filter { $0.lastPathComponent.hasPrefix("teleprompter_") && $0.pathExtension == "mp4" }

            for file in teleprompterFiles {
                try? FileManager.default.removeItem(at: file)
            }

            if !teleprompterFiles.isEmpty {
                print("已清理 \(teleprompterFiles.count) 个旧的临时视频文件")
            }
        } catch {
            print("清理旧视频文件失败: \(error.localizedDescription)")
        }
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

        // 添加后置空行（让最后几行能完整滚动并停留）
        // 高亮区域在 40% 位置，需要足够的空行让最后一行能滚动到屏幕顶部
        // 视频高度 960，高亮区域在 384，需要更多空行确保最后内容能完全向上滚动
        // 增加到 15 行空行，确保所有内容都能完整显示
        for _ in 0..<15 {
            result.append(" ")  // 空格占位
        }

        print("原始行数: \(originalLines.filter { !$0.isEmpty }.count), 拆分后行数: \(result.count)（含前后缓冲行）")
        return result
    }

    func createVideoFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("teleprompter_\(UUID().uuidString).mp4")

        // 保存 URL 用于后续清理
        self.videoURL = videoURL

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

        // 不使用循环，直接使用 offset（播放完就停止）
        let currentOffset = offset

        // 高亮区域：屏幕中央偏上位置（从顶部算起 40%）
        let highlightY = videoSize.height * 0.4

        for (index, lineText) in lines.enumerated() {
            // 计算文字位置（从上往下滚动，下一句在下面）
            let yPosition = CGFloat(index) * lineHeight
            let y = highlightY - yPosition + currentOffset

            // 不实现循环，允许文字滚动到屏幕外

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
        // 清理视频文件
        if let url = videoURL {
            try? FileManager.default.removeItem(at: url)
            print("已删除临时视频文件: \(url.lastPathComponent)")
            videoURL = nil
        }
    }

    deinit {
        // 对象销毁时也清理视频文件
        stop()
    }
}
