import AppKit
import Carbon
import ApplicationServices
import OSLog

final class PasteService {
    private let logger = Logger(subsystem: "com.bufferly.app", category: "PasteService")
    private let closeWindow: @MainActor () -> Void

    init(closeWindow: @escaping @MainActor () -> Void) {
        self.closeWindow = closeWindow
    }

    @MainActor
    func paste(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let data = item.binaryData, item.type == "public.image" {
            pasteboard.setData(data, forType: .png)
        } else if let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        }

        closeWindow()

        guard AXIsProcessTrusted() else {
            logger.warning("Accessibility not granted — item copied to clipboard but auto-paste skipped")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.simulatePasteCommand()
        }
    }

    private func simulatePasteCommand() {
        let source = CGEventSource(stateID: .hidSystemState)

        let kVK_ANSI_V: CGKeyCode = 0x09
        let cmdFlag = CGEventFlags.maskCommand

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_V, keyDown: true) else {
            logger.error("Failed to create keyDown CGEvent")
            return
        }
        keyDown.flags = cmdFlag
        keyDown.post(tap: .cghidEventTap)

        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_V, keyDown: false) else {
            logger.error("Failed to create keyUp CGEvent")
            return
        }
        keyUp.flags = cmdFlag
        keyUp.post(tap: .cghidEventTap)
    }
}
