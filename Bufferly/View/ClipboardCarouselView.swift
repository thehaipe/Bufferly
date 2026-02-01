import SwiftUI
import SwiftData

enum FocusTarget: Hashable {
    case row(Int)
    case note(Int)
}

struct ClipboardCarouselView: View {
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var items: [ClipboardItem]
    @State private var selectedIndex: Int = 0
    @FocusState private var focus: FocusTarget?

    private let windowWidth: CGFloat = 338
    private let windowHeight: CGFloat = 158
    private let itemHeight: CGFloat = 60
    private let spacing: CGFloat = 4

    private var isEditingNote: Bool {
        if case .note = focus { return true }
        return false
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            if items.isEmpty {
                Text("Empty")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        VStack(spacing: spacing) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    index: index,
                                    isSelected: index == selectedIndex,
                                    focus: $focus,
                                    onSelectRow: {
                                        selectedIndex = index
                                    }
                                )
                                .focused($focus, equals: .row(index))
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    PasteService.shared.paste(item: item)
                                }
                                .frame(height: itemHeight)
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.6)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                        .blur(radius: phase.isIdentity ? 0 : 2)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .defaultFocus($focus, .row(0))
                        .onChange(of: selectedIndex) { _, newIndex in
                            withAnimation {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
        .frame(width: windowWidth, height: windowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: items) { _, _ in
            guard !isEditingNote else { return }
            selectedIndex = 0
            focus = .row(0)
        }
        .onAppear {
            if !items.isEmpty {
                focus = .row(0)
            }
        }
        .onKeyPress(.downArrow) {
            guard !isEditingNote else { return .ignored }
            if selectedIndex < items.count - 1 {
                selectedIndex += 1
                focus = .row(selectedIndex)
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard !isEditingNote else { return .ignored }
            if selectedIndex > 0 {
                selectedIndex -= 1
                focus = .row(selectedIndex)
            }
            return .handled
        }
        .onKeyPress(.return) {
            guard !isEditingNote else { return .ignored }
            guard selectedIndex < items.count else { return .ignored }
            PasteService.shared.paste(item: items[selectedIndex])
            return .handled
        }
    }
}

struct ClipboardItemRow: View {
    @Bindable var item: ClipboardItem
    let index: Int
    var isSelected: Bool
    var focus: FocusState<FocusTarget?>.Binding
    var onSelectRow: () -> Void

    private var isEditing: Bool {
        focus.wrappedValue == .note(index)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let data = item.binaryData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    }
            } else {
                Image(systemName: item.type.contains("image") ? "photo" : "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Image")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    TextField("Note", text: Binding(
                        get: { item.note ?? "" },
                        set: { item.note = $0.isEmpty ? nil : $0 }
                    ))
                    .focused(focus, equals: .note(index))
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.black.opacity(0.1))
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    }
                    .frame(width: 80)
                    .onTapGesture {
                        onSelectRow()
                        focus.wrappedValue = .note(index)
                    }

                    Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "return")
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .tertiary)
                .opacity(isSelected ? 1.0 : 0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
        }
        .padding(.horizontal, 10)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.return) {
            if isEditing {
                focus.wrappedValue = .row(index)
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    ClipboardCarouselView()
        .padding()
        .background(Color.blue)
}
