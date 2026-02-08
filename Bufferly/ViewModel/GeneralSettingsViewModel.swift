import AppKit
import ApplicationServices

@Observable
@MainActor
final class GeneralSettingsViewModel {
    var isAccessibilityTrusted: Bool

    init() {
        self.isAccessibilityTrusted = AXIsProcessTrusted()
    }

    func refreshAccessibilityStatus() {
        isAccessibilityTrusted = AXIsProcessTrusted()
    }

    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
