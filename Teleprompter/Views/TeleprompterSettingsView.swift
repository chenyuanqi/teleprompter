import SwiftUI
import SwiftData
import AVKit
import AVFoundation

struct TeleprompterSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var script: Script

    @State private var settings = TeleprompterSettings()
    @State private var showingTeleprompter = false
    @State private var showingPiPTeleprompter = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 预览区域
                        PreviewCard(content: script.content, settings: settings)

                        // 滚动速度
                        SettingSlider(
                            title: "滚动速度",
                            value: $settings.scrollSpeed,
                            range: 1.0...10.0,
                            valueFormatter: { String(format: "%.1f 秒/行", $0) }
                        )

                        // 字号
                        SettingSlider(
                            title: "字号",
                            value: Binding(
                                get: { Double(settings.fontSize) },
                                set: { settings.fontSize = CGFloat($0) }
                            ),
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
                                settings.rotation = (settings.rotation + 90) % 360
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.portrait.rotate")
                                    Text("\(settings.rotation)°")
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
                                            isSelected: settings.textColor == color,
                                            action: {
                                                settings.textColor = color
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

                // 底部按钮
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        // 画中画悬浮窗按钮（推荐）
                        Button(action: {
                            showingPiPTeleprompter = true
                        }) {
                            HStack {
                                Image(systemName: "pip.enter")
                                    .font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("开启画中画悬浮")
                                            .font(.system(size: 18, weight: .medium))
                                        Text("推荐")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.yellow)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.yellow.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    Text("可切换到其他 App")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color(red: 1.0, green: 0.3, blue: 0.4))
                            .cornerRadius(25)
                        }

                        // 普通悬浮窗按钮
                        Button(action: {
                            showingTeleprompter = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.inset.filled")
                                    .font(.system(size: 18))
                                Text("App 内悬浮窗")
                                    .font(.system(size: 16))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.3))
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
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
        .fullScreenCover(isPresented: $showingTeleprompter) {
            FloatingTeleprompterView(script: script, settings: settings)
        }
        .fullScreenCover(isPresented: $showingPiPTeleprompter) {
            PiPTeleprompterView(script: script, settings: settings)
        }
        .preferredColorScheme(.dark)
    }
}

struct PreviewCard: View {
    let content: String
    let settings: TeleprompterSettings

    var lines: [String] {
        content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.prefix(5).enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.system(size: settings.fontSize * 0.5))
                        .foregroundColor(index == 0 ? settings.textColor : .gray)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(white: 0.12))
            .cornerRadius(12)
            .rotationEffect(.degrees(Double(settings.rotation)))
            .frame(width: geometry.size.width, height: 150, alignment: .center)
        }
        .frame(height: 150)
        .padding(.horizontal)
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

// MARK: - PiP Teleprompter View
struct PiPTeleprompterView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var script: Script
    let settings: TeleprompterSettings

    @StateObject private var pipController = PiPTeleprompterController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 图标
                Image(systemName: "pip")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("画中画提词器")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("开启后可以切换到其他 App\n提词窗口会一直悬浮显示")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // 状态显示
                if pipController.isGeneratingVideo {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("正在生成视频...")
                            .font(.system(size: 16))
                            .foregroundColor(.white)

                        Text("首次生成需要几秒钟，请耐心等待")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)
                } else if pipController.isActive {
                    VStack(spacing: 16) {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("悬浮窗已开启")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }

                        Text("现在可以切换到相机 App 了")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Text("提词内容：")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, 10)

                        ScrollView {
                            Text(script.content)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding()
                        }
                        .frame(height: 150)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .padding(.horizontal, 30)
                    }
                } else if !pipController.isPiPSupported {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("此设备不支持画中画功能")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }
                } else if let errorMessage = pipController.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }

                Spacer()

                // 按钮区域
                VStack(spacing: 16) {
                    if pipController.isActive {
                        Button(action: {
                            pipController.stopPiP()
                        }) {
                            HStack {
                                Image(systemName: "pip.exit")
                                    .font(.system(size: 20))
                                Text("停止悬浮")
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
                                    Text("开启悬浮提词器")
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

                    Button(action: {
                        pipController.stopPiP()
                        dismiss()
                    }) {
                        Text("关闭")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            // 不要在这里停止 PiP，让它继续运行
        }
    }
}

// MARK: - PiP Teleprompter Controller
class PiPTeleprompterController: NSObject, ObservableObject {
    @Published var isActive = false
    @Published var isPiPSupported = AVPictureInPictureController.isPictureInPictureSupported()
    @Published var isGeneratingVideo = false
    @Published var errorMessage: String?

    private var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var videoRenderer: TeleprompterVideoRenderer?

    override init() {
        super.init()
        setupAudioSession()
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
                self.playerLayer = layer

                // 创建 PiP 控制器
                if let pipController = AVPictureInPictureController(playerLayer: layer) {
                    pipController.delegate = self
                    pipController.canStartPictureInPictureAutomaticallyFromInline = true
                    self.pipController = pipController

                    // 启动播放
                    player.play()

                    // 延迟启动 PiP
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("尝试启动画中画...")
                        pipController.startPictureInPicture()
                    }
                } else {
                    self.errorMessage = "无法创建画中画控制器"
                    print("无法创建画中画控制器")
                }
            }
        }
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
        player?.pause()
        videoRenderer?.stop()
        isActive = false
    }

    deinit {
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
        print("PiP failed to start: \(error)")
        DispatchQueue.main.async {
            self.isActive = false
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

    private let videoSize = CGSize(width: 720, height: 1280)
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

            let lineHeight = settings.fontSize + 12
            let pointsPerSecond = lineHeight / CGFloat(settings.scrollSpeed)
            let speed = pointsPerSecond / CGFloat(fps)

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
        let lineHeight = settings.fontSize + 12

        context.saveGState()
        context.translateBy(x: 0, y: videoSize.height)
        context.scaleBy(x: 1, y: -1)

        let highlightY = videoSize.height * 0.4

        for (index, line) in lines.enumerated() {
            guard !line.isEmpty else { continue }

            let y = CGFloat(index) * lineHeight - offset + videoSize.height * 0.3

            // 跳过屏幕外的文本
            guard y > -lineHeight && y < videoSize.height + lineHeight else { continue }

            // 确定颜色（高亮当前行）
            let distance = abs(y - highlightY)
            let isHighlighted = distance < lineHeight * 1.5
            let color = isHighlighted ? UIColor(settings.textColor) : UIColor.gray.withAlphaComponent(0.7)

            // 绘制文本
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: settings.fontSize),
                .foregroundColor: color
            ]

            let attributedString = NSAttributedString(string: line, attributes: attributes)
            let textSize = attributedString.size()
            let x = (videoSize.width - textSize.width) / 2

            attributedString.draw(at: CGPoint(x: x, y: videoSize.height - y - lineHeight))
        }

        context.restoreGState()
    }

    func stop() {
        // 清理资源
    }
}
