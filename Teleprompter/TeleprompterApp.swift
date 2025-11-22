import SwiftUI
import SwiftData

@main
struct TeleprompterApp: App {
    let modelContainer: ModelContainer
    @State private var isLaunching = true

    init() {
        do {
            modelContainer = try ModelContainer(for: Script.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .modelContainer(modelContainer)

                if isLaunching {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isLaunching = false
                    }
                }
            }
        }
    }
}
