import SwiftUI
import UIKit

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

private struct CanvasBlock: Identifiable, Equatable {
    enum Kind {
        case text
        case image
    }

    var id: UUID
    var kind: Kind
    var key: String
    var value: String
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var fontSize: CGFloat
    var isBold: Bool
    var isItalic: Bool
    var color: Color
}

struct CategoryProfileEditorView: View {
    @State private var profile: IngredientCategoryProfile
    @StateObject private var store = IngredientCategoryProfileStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPaper = "40×30mm"
    @State private var blocks: [CanvasBlock] = []
    @State private var selectedBlockID: UUID?
    @State private var pendingImage: UIImage?
    @State private var showingImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var previewData: [String: String] = [
        "name": "牛奶",
        "thawTime": "0年0月0日4时0分",
        "preserveTime": "0年0月2日0时0分",
        "useTime": "2026/03/04 13:20",
        "expTime": "2026/03/06 13:20",
        "operatorName": "Alice",
        "storageCondition": "2-6°C",
        "stock": "8",
        "unit": "盒"
    ]

    private let papers: [String: CGSize] = [
        "A4": CGSize(width: 210, height: 297),
        "58mm": CGSize(width: 58, height: 40),
        "80mm": CGSize(width: 80, height: 50),
        "40×30mm": CGSize(width: 40, height: 30)
    ]

    init(profile: IngredientCategoryProfile) {
        _profile = State(initialValue: profile)
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
                    }
                }
            }

            Section("纸张") {
                Picker("尺寸", selection: $selectedPaper) {
                    ForEach(Array(papers.keys), id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("画布工具栏") {
                HStack {
                    Button("添加文本") {
                        addTextBlock()
                    }
                    Spacer()
                    Button("添加图片框") {
                        addImageBlock()
                    }
                }
                HStack {
                    Button("点击上传") {
                        pickerSourceType = .photoLibrary
                        showingImagePicker = true
                    }
                    Spacer()
                    Button("拍照") {
                        pickerSourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
                        showingImagePicker = true
                    }
                }
                if let index = selectedBlockIndex {
                    Stepper("字体 \(Int(blocks[index].fontSize))", value: $blocks[index].fontSize, in: 8...40)
                    Toggle("加粗", isOn: $blocks[index].isBold)
                    Toggle("斜体", isOn: $blocks[index].isItalic)
                    ColorPicker("颜色", selection: $blocks[index].color)
                    Button("删除选中框") {
                        let id = blocks[index].id
                        blocks.removeAll(where: { $0.id == id })
                        selectedBlockID = nil
                    }
                    .foregroundColor(.red)
                }
            }

            Section("字段素材") {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(profile.fields.filter(\.enabled)) { field in
                            Button(field.alias) {
                                addFieldBlock(field)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Section("可视化预览") {
                canvasView
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
                        loadCanvas(from: refreshed.activeTemplate.template)
                    }
                }
            }
        }
        .navigationTitle("分类编辑")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCanvas(from: profile.activeTemplate.template)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: pickerSourceType) { image in
                pendingImage = resizeImage(image)
                if let index = selectedBlockIndex, blocks[index].kind == .image {
                    blocks[index].value = "image"
                }
                showingImagePicker = false
            }
        }
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

    private var selectedBlockIndex: Int? {
        blocks.firstIndex(where: { $0.id == selectedBlockID })
    }

    private var canvasSize: CGSize {
        let selected = papers[selectedPaper] ?? CGSize(width: 40, height: 30)
        let ratio = selected.width / selected.height
        return CGSize(width: 300, height: 300 / ratio)
    }

    private var canvasView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.03))
            ForEach(blocks) { block in
                canvasBlockView(block)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func canvasBlockView(_ block: CanvasBlock) -> some View {
        Group {
            if block.kind == .image {
                ZStack {
                    Rectangle().fill(Color.blue.opacity(0.1))
                    if pendingImage != nil {
                        Image(uiImage: pendingImage!)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(previewData[block.key] ?? block.value)
                    .font(.system(size: block.fontSize, weight: block.isBold ? .bold : .regular, design: .default))
                    .rotationEffect(.degrees(block.isItalic ? -4 : 0))
                    .foregroundColor(block.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(4)
            }
        }
        .frame(width: block.width, height: block.height)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(block.id == selectedBlockID ? Color.blue : Color.clear, lineWidth: 1)
        )
        .position(x: block.x, y: block.y)
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
                    blocks[index].x = min(max(value.location.x, 0), canvasSize.width)
                    blocks[index].y = min(max(value.location.y, 0), canvasSize.height)
                    selectedBlockID = block.id
                }
        )
        .onTapGesture {
            selectedBlockID = block.id
        }
    }

    private func addFieldBlock(_ field: IngredientFieldDefinition) {
        let id = UUID()
        let block = CanvasBlock(
            id: id,
            kind: .text,
            key: field.key.rawValue,
            value: field.alias,
            x: 80,
            y: CGFloat(40 + blocks.count * 24),
            width: 120,
            height: 24,
            fontSize: 12,
            isBold: false,
            isItalic: false,
            color: .primary
        )
        blocks.append(block)
        selectedBlockID = id
    }

    private func addTextBlock() {
        let id = UUID()
        blocks.append(
            CanvasBlock(
                id: id,
                kind: .text,
                key: "name",
                value: "文本",
                x: 90,
                y: 40,
                width: 120,
                height: 24,
                fontSize: 12,
                isBold: false,
                isItalic: false,
                color: .primary
            )
        )
        selectedBlockID = id
    }

    private func addImageBlock() {
        let id = UUID()
        blocks.append(
            CanvasBlock(
                id: id,
                kind: .image,
                key: "image",
                value: "image",
                x: 220,
                y: 80,
                width: 72,
                height: 54,
                fontSize: 10,
                isBold: false,
                isItalic: false,
                color: .primary
            )
        )
        selectedBlockID = id
    }

    private func loadCanvas(from rawTemplate: String) {
        guard let payload = LabelTemplateEngine.decodeCanvasTemplate(rawTemplate) else {
            blocks = [
                CanvasBlock(id: UUID(), kind: .text, key: "name", value: "名称", x: 80, y: 30, width: 140, height: 24, fontSize: 12, isBold: true, isItalic: false, color: .primary),
                CanvasBlock(id: UUID(), kind: .text, key: "useTime", value: "使用时间", x: 80, y: 60, width: 170, height: 22, fontSize: 10, isBold: false, isItalic: false, color: .primary),
                CanvasBlock(id: UUID(), kind: .text, key: "expTime", value: "到期时间", x: 80, y: 86, width: 170, height: 22, fontSize: 10, isBold: false, isItalic: false, color: .primary)
            ]
            return
        }
        blocks = payload.items.map {
            CanvasBlock(
                id: $0.id,
                kind: $0.kind == .image ? .image : .text,
                key: $0.key,
                value: $0.key,
                x: $0.x,
                y: $0.y,
                width: $0.width,
                height: $0.height,
                fontSize: $0.fontSize,
                isBold: $0.isBold,
                isItalic: $0.isItalic,
                color: Color(hex: $0.colorHex)
            )
        }
        selectedPaper = payload.paper
    }

    private func save() {
        var updated = profile
        updated.updatedAt = Date()
        let payload = CanvasTemplatePayload(
            paper: selectedPaper,
            items: blocks.map {
                CanvasTemplateItem(
                    id: $0.id,
                    kind: $0.kind == .image ? .image : .text,
                    key: $0.key,
                    x: $0.x,
                    y: $0.y,
                    width: $0.width,
                    height: $0.height,
                    fontSize: $0.fontSize,
                    isBold: $0.isBold,
                    isItalic: $0.isItalic,
                    colorHex: $0.colorHexString
                )
            }
        )
        let encoded = LabelTemplateEngine.encodeCanvasTemplate(payload)
        store.saveTemplate(profileID: updated.id, template: encoded)
        if let persisted = store.profile(by: updated.id) {
            updated.templateVersions = persisted.templateVersions
            updated.activeTemplateVersion = persisted.activeTemplateVersion
        }
        store.upsert(updated)
        dismiss()
    }

    private func resizeImage(_ image: UIImage) -> UIImage {
        let target = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPick: (UIImage) -> Void

        init(onPick: @escaping (UIImage) -> Void) {
            self.onPick = onPick
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onPick(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        if let value = Int(cleaned, radix: 16) {
            let r = Double((value >> 16) & 0xFF) / 255
            let g = Double((value >> 8) & 0xFF) / 255
            let b = Double(value & 0xFF) / 255
            self = Color(red: r, green: g, blue: b)
        } else {
            self = .primary
        }
    }
}

private extension CanvasBlock {
    var colorHexString: String {
        UIColor(color).toHexString()
    }
}

private extension UIColor {
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
