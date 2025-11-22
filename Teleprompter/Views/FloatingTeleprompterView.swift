import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Camera View
struct CameraView: UIViewRepresentable {
    class CameraPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // No updates needed
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var isRecording = false

    let session = AVCaptureSession()
    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentRecordingURL: URL?

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }

    private func setupCamera() {
        session.beginConfiguration()

        // 设置高质量视频
        session.sessionPreset = .high

        // 添加视频输入
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)

        // 添加音频输入
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        // 添加视频输出
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            videoOutput = movieOutput
        }

        session.commitConfiguration()
    }

    func startSession() {
        guard !isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        guard isSessionRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    func startRecording() {
        guard let videoOutput = videoOutput, !isRecording else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoPath = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).mov")
        currentRecordingURL = videoPath

        videoOutput.startRecording(to: videoPath, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        guard let videoOutput = videoOutput, isRecording else { return }
        videoOutput.stopRecording()
    }

    func switchCamera() {
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }

        session.beginConfiguration()
        session.removeInput(currentInput)

        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .front ? .back : .front

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice),
              session.canAddInput(newInput) else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }

        session.addInput(newInput)
        session.commitConfiguration()
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false

            if error == nil {
                // 保存视频到相册
                UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
            }
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
    }
}

// MARK: - Floating Teleprompter View
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

    // 相机管理器
    @StateObject private var cameraManager = CameraManager()

    // 悬浮窗尺寸（横向铺满，纵向占四分之一）
    @State private var windowWidth: CGFloat = UIScreen.main.bounds.width
    @State private var windowHeight: CGFloat = UIScreen.main.bounds.height / 4

    var body: some View {
        ZStack {
            // 相机预览背景
            if cameraManager.isAuthorized {
                CameraView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("需要相机权限")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Text("请在设置中允许访问相机")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Button("打开设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(red: 1.0, green: 0.3, blue: 0.4))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }

            // 点击区域用于显示/隐藏控制栏
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        showControls.toggle()
                    }
                    if showControls {
                        resetControlsTimer()
                    }
                }

            // 可拖动的悬浮提词器窗口
            VStack(spacing: 0) {
                // 控制栏（自动隐藏）
                if showControls {
                    HStack(spacing: 16) {
                        // 拖动手柄
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 30)

                        Spacer()

                        // 切换摄像头
                        Button(action: {
                            cameraManager.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }

                        // 背景透明度控制
                        Button(action: {
                            backgroundOpacity = backgroundOpacity > 0.3 ? 0.3 : 0.7
                        }) {
                            Image(systemName: backgroundOpacity > 0.5 ? "circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }

                        // 暂停/播放滚动
                        Button(action: togglePause) {
                            Image(systemName: isScrolling ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }

                        // 重新开始
                        Button(action: restartScrolling) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // 关闭按钮
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 提词器内容窗口
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
            }
            .shadow(color: .black.opacity(0.4), radius: 12)
            .position(windowPosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 显示控制栏
                        if !showControls {
                            withAnimation {
                                showControls = true
                            }
                        }
                        // 更新窗口位置
                        windowPosition = value.location
                    }
                    .onEnded { _ in
                        // 拖动结束后重置控制栏定时器
                        resetControlsTimer()
                    }
            )

            // 底部录制按钮
            VStack {
                Spacer()

                Button(action: {
                    if cameraManager.isRecording {
                        cameraManager.stopRecording()
                    } else {
                        cameraManager.startRecording()
                    }
                    resetControlsTimer()
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)

                        if cameraManager.isRecording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 初始化窗口位置在屏幕顶部居中
            windowPosition = CGPoint(
                x: UIScreen.main.bounds.width / 2,
                y: windowHeight / 2 + 80
            )
            startScrolling()
            startControlsTimer()
            cameraManager.startSession()
        }
        .onDisappear {
            stopScrolling()
            stopControlsTimer()
            cameraManager.stopSession()
            if cameraManager.isRecording {
                cameraManager.stopRecording()
            }
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
