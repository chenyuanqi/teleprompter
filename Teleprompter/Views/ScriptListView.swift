import SwiftUI
import SwiftData

struct ScriptListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]

    @State private var showingEditor = false
    @State private var selectedScript: Script?
    @State private var showingSettings = false
    @State private var scriptForTeleprompter: Script?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 新建台词卡片
                        Button(action: {
                            selectedScript = nil
                            showingEditor = true
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                                Text("新建台词")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .background(Color(white: 0.15))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // 台词草稿标题
                        if !scripts.isEmpty {
                            HStack {
                                Text("台词草稿")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)

                            // 台词列表
                            LazyVStack(spacing: 12) {
                                ForEach(scripts) { script in
                                    ScriptRowView(
                                        script: script,
                                        onEdit: {
                                            selectedScript = script
                                            showingEditor = true
                                        },
                                        onTeleprompter: {
                                            scriptForTeleprompter = script
                                            showingSettings = true
                                        },
                                        onDelete: {
                                            deleteScript(script)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("元气提词器")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showingEditor) {
            ScriptEditorView(script: selectedScript)
        }
        .sheet(isPresented: $showingSettings) {
            if let script = scriptForTeleprompter {
                TeleprompterSettingsView(script: script)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func deleteScript(_ script: Script) {
        modelContext.delete(script)
    }
}

struct ScriptRowView: View {
    let script: Script
    let onEdit: () -> Void
    let onTeleprompter: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(script.displayTitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(script.previewContent)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)

            HStack {
                Text(script.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))

                Spacer()

                Button(action: onTeleprompter) {
                    Text("悬浮提词")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.3))
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ScriptListView()
        .modelContainer(for: Script.self, inMemory: true)
}
