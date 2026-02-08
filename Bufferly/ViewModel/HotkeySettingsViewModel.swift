import Carbon
import AppKit

@Observable
@MainActor
final class HotkeySettingsViewModel {
    var isRecording: Bool = false

    private let hotKeyService: HotKeyService

    init(hotKeyService: HotKeyService = .shared) {
        self.hotKeyService = hotKeyService
    }

    var currentKeyCode: UInt32 {
        hotKeyService.currentKeyCode
    }

    var currentModifiers: UInt32 {
        hotKeyService.currentModifiers
    }

    func modifierSymbols() -> [String] {
        hotKeyService.modifierSymbols(for: currentModifiers)
    }

    func keyString() -> String {
        hotKeyService.keyString(for: currentKeyCode)
    }

    func startRecording() {
        isRecording = true
    }

    func cancelRecording() {
        isRecording = false
    }

    func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        hotKeyService.register(keyCode: keyCode, modifiers: modifiers)
        isRecording = false
    }
}
