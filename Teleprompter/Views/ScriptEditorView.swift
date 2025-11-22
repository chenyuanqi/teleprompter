import SwiftUI
import SwiftData

struct ScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var script: Script

    @State private var content: String = ""
    @State private var isNewScript = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    TextEditor(text: $content)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.black)
                        .padding()
                        .focused($isTextEditorFocused)
                }
            }
            .navigationTitle(isNewScript ? "新建台词" : "编辑台词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        cancelEdit()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveScript()
                    }
                    .foregroundColor(.pink)
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            content = script.content
            isNewScript = script.content.isEmpty
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextEditorFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveScript() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContent.isEmpty {
            // 如果内容为空，删除这个草稿
            modelContext.delete(script)
        } else {
            // 更新内容
            script.content = content
            script.updatedAt = Date()
        }

        dismiss()
    }

    private func cancelEdit() {
        if isNewScript && script.content.isEmpty {
            // 如果是新建的空草稿，取消时删除
            modelContext.delete(script)
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Script.self, configurations: config)
    let script = Script(content: "示例台词内容")
    container.mainContext.insert(script)

    return ScriptEditorView(script: script)
        .modelContainer(container)
}
