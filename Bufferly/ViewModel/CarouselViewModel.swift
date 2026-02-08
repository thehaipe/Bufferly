import SwiftUI
import SwiftData

@Observable
@MainActor
final class CarouselViewModel {
    var selectedIndex: Int = 0
    var showClearConfirmation: Bool = false

    private let pasteAction: (ClipboardItem) -> Void

    init(pasteAction: @escaping (ClipboardItem) -> Void) {
        self.pasteAction = pasteAction
    }

    func pasteItem(_ item: ClipboardItem) {
        pasteAction(item)
    }

    func pasteSelected(items: [ClipboardItem]) {
        guard selectedIndex < items.count else { return }
        pasteAction(items[selectedIndex])
    }

    func moveUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func moveDown(itemCount: Int) {
        if selectedIndex < itemCount - 1 {
            selectedIndex += 1
        }
    }

    func resetSelection() {
        selectedIndex = 0
    }

    func requestClearConfirmation() {
        showClearConfirmation = true
    }

    func cancelClearConfirmation() {
        showClearConfirmation = false
    }

    func confirmClear(modelContext: ModelContext) {
        try? modelContext.delete(model: ClipboardItem.self)
        withAnimation(.spring(duration: 0.2)) {
            showClearConfirmation = false
        }
    }
}
