import SwiftUI
import SwiftData

struct ScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let script: Script?

    @State private var content: String = ""
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
            .navigationTitle(script == nil ? "新建台词" : "编辑台词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
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
            if let script = script {
                content = script.content
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextEditorFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveScript() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            dismiss()
            return
        }

        if let existingScript = script {
            existingScript.content = content
            existingScript.updatedAt = Date()
        } else {
            let newScript = Script(content: content)
            modelContext.insert(newScript)
        }

        dismiss()
    }
}

#Preview {
    ScriptEditorView(script: nil)
        .modelContainer(for: Script.self, inMemory: true)
}
