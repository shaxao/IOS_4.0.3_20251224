import SwiftUI

struct CategoryProfileManagementView: View {
    @StateObject private var store = IngredientCategoryProfileStore.shared
    @State private var showingCreate = false

    var body: some View {
        List {
            ForEach(store.profiles) { profile in
                NavigationLink {
                    CategoryProfileEditorView(profile: profile)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                        Text("模板 v\(profile.activeTemplateVersion) · 字段 \(profile.fields.filter(\.enabled).count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                indexSet.map { store.profiles[$0].id }.forEach(store.delete)
            }
        }
        .navigationTitle("分类与模板")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationView {
                CategoryProfileEditorView(profile: IngredientCategoryProfile(name: "新分类"))
            }
        }
    }
}

struct CategoryProfileEditorView: View {
    @State private var profile: IngredientCategoryProfile
    @StateObject private var store = IngredientCategoryProfileStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var templateText: String
    @State private var previewData: [String: String] = [
        "name": "牛奶",
        "thawTime": "2026/03/04 09:20",
        "useTime": "2026/03/04 11:20",
        "expTime": "2026/03/05 11:20",
        "operatorName": "Alice",
        "storageCondition": "2-6°C",
        "stock": "8",
        "unit": "盒"
    ]

    init(profile: IngredientCategoryProfile) {
        _profile = State(initialValue: profile)
        _templateText = State(initialValue: profile.activeTemplate.template)
    }

    var body: some View {
        Form {
            Section("基础") {
                TextField("分类名称", text: $profile.name)
            }

            Section("字段开关与别名") {
                ForEach(profile.fields.indices, id: \.self) { index in
                    HStack {
                        Toggle("", isOn: $profile.fields[index].enabled)
                            .labelsHidden()
                        TextField("别名", text: $profile.fields[index].alias)
                        Spacer()
                        Text("{{\(profile.fields[index].key.rawValue)}}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("模板编辑（40×30mm）") {
                TextEditor(text: $templateText)
                    .frame(minHeight: 130)
                Text("可用占位符: \(profile.fields.filter(\.enabled).map { "{{\($0.key.rawValue)}}" }.joined(separator: " "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    Text("预览")
                        .font(.headline)
                    Text(LabelTemplateEngine.render(templateText, with: previewData))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .padding(8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4))
                        }
                }
            }

            Section("模板版本") {
                Picker("当前版本", selection: $profile.activeTemplateVersion) {
                    ForEach(profile.templateVersions.sorted(by: { $0.version > $1.version })) { version in
                        Text("v\(version.version)").tag(version.version)
                    }
                }
                Button("回退到当前所选版本") {
                    store.rollbackTemplate(profileID: profile.id, to: profile.activeTemplateVersion)
                    if let refreshed = store.profile(by: profile.id) {
                        profile = refreshed
                        templateText = refreshed.activeTemplate.template
                    }
                }
            }
        }
        .navigationTitle("分类编辑")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    save()
                }
            }
        }
    }

    private func save() {
        var updated = profile
        updated.updatedAt = Date()
        store.saveTemplate(profileID: updated.id, template: templateText)
        if let persisted = store.profile(by: updated.id) {
            updated.templateVersions = persisted.templateVersions
            updated.activeTemplateVersion = persisted.activeTemplateVersion
        } else {
            let nextVersion = (updated.templateVersions.map(\.version).max() ?? 0) + 1
            updated.templateVersions.append(LabelTemplateVersion(version: nextVersion, template: templateText))
            updated.activeTemplateVersion = nextVersion
        }
        store.upsert(updated)
        dismiss()
    }
}
