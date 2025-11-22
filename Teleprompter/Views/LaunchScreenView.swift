import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Logo 图标
                ZStack {
                    // 背景光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.4).opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.6 : 0.3)

                    // 主图标
                    ZStack {
                        // 外圆环
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.3, blue: 0.4),
                                        Color(red: 1.0, green: 0.5, blue: 0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 100, height: 100)

                        // 滚动文字图标
                        VStack(spacing: 6) {
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.9, blue: 0.4),
                                                Color(red: 0.3, green: 1.0, blue: 0.5)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 50 - CGFloat(index * 10), height: 4)
                                    .opacity(index == 0 ? 1.0 : 0.5)
                                    .offset(y: isAnimating ? -30 : 0)
                                    .animation(
                                        Animation.easeInOut(duration: 2.0)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                }

                // 应用名称
                VStack(spacing: 8) {
                    Text("提词器")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    Color(white: 0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("让演讲更自信")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .opacity(isAnimating ? 1.0 : 0)

                Spacer()

                // 加载指示器
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(red: 1.0, green: 0.3, blue: 0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LaunchScreenView()
}
