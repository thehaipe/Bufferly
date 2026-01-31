import Carbon
import AppKit
import SwiftUI
import OSLog

@Observable
final class HotKeyService {
    static let shared = HotKeyService()
    
    var onHotKeyTriggered: (() -> Void)?
    var isEnabled = true
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let logger = Logger(subsystem: "com.bufferly.app", category: "HotKeyService")
    
    // Default: Ctrl + Shift + V (Code 9)
    private let defaultKeyCode: UInt32 = 9
    private let defaultModifiers: UInt32 = UInt32(controlKey | shiftKey)
    
    var currentKeyCode: UInt32
    var currentModifiers: UInt32
    
    private init() {
        let savedCode = UserDefaults.standard.integer(forKey: "hotkey_code")
        let savedMods = UserDefaults.standard.integer(forKey: "hotkey_modifiers")
        
        if savedCode == 0 && savedMods == 0 {
            self.currentKeyCode = defaultKeyCode
            self.currentModifiers = defaultModifiers
        } else {
            self.currentKeyCode = UInt32(savedCode)
            self.currentModifiers = UInt32(savedMods)
        }
    }
    
    func register(keyCode: UInt32, modifiers: UInt32) {
        self.currentKeyCode = keyCode
        self.currentModifiers = modifiers
        
        UserDefaults.standard.set(keyCode, forKey: "hotkey_code")
        UserDefaults.standard.set(modifiers, forKey: "hotkey_modifiers")
        
        register()
    }
    
    func register() {
        guard isEnabled else { return }
        unregister()
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x42464C59) // 'BFLY'
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(
            currentKeyCode,
            currentModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            logger.error("Error registering global hotkey: \(status)")
            hotKeyRef = nil 
            return
        }
        
        logger.info("Registered hotkey: \(self.currentKeyCode) + \(self.currentModifiers)")

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        if eventHandlerRef == nil {
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (_, event, _) -> OSStatus in
                    DispatchQueue.main.async {
                        HotKeyService.shared.onHotKeyTriggered?()
                    }
                    return noErr
                },
                1,
                &eventType,
                nil,
                &eventHandlerRef
            )
        }
    }
    
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    // MARK: - Helpers
    
    func modifierSymbols(for modifiers: UInt32) -> [String] {
        var symbols: [String] = []
        if (modifiers & UInt32(controlKey)) != 0 { symbols.append("⌃") }
        if (modifiers & UInt32(optionKey)) != 0 { symbols.append("⌥") }
        if (modifiers & UInt32(shiftKey)) != 0 { symbols.append("⇧") }
        if (modifiers & UInt32(cmdKey)) != 0 { symbols.append("⌘") }
        return symbols
    }
    
    func keyString(for code: UInt32) -> String {
        switch code {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "⏎"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "⇥"
        case 49: return "␣"
        case 50: return "`"
        case 51: return "⌫"
        case 53: return "⎋"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "?"
        }
    }
    
    deinit {
        unregister()
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}
