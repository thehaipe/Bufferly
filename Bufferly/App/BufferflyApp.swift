import SwiftUI
import SwiftData
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardService: ClipboardService?
    private var overlayService: OverlayWindowService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and App Switcher
        NSApp.setActivationPolicy(.accessory)

        let container = BufferflyApp.columnModelContainer

        // Setup Clipboard Service
        let clipboard = ClipboardService(container: container)
        clipboard.startMonitoring()
        self.clipboardService = clipboard

        // Resolve circular dependency: PasteService needs closeWindow, OverlayWindowService needs PasteService
        var overlayRef: OverlayWindowService?
        let pasteService = PasteService(closeWindow: { overlayRef?.closeWindow() })
        let overlay = OverlayWindowService(container: container, pasteService: pasteService)
        overlayRef = overlay
        self.overlayService = overlay

        // Setup Hotkeys
        HotKeyService.shared.register()
        HotKeyService.shared.onHotKeyTriggered = { [weak self] in
            Task { @MainActor in
                self?.overlayService?.toggleWindow()
            }
        }
    }
}

@main
struct BufferflyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    static var columnModelContainer: ModelContainer = {
        let schema = Schema([
            ClipboardItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        Settings {
            RootView()
        }
        .modelContainer(Self.columnModelContainer)
        
        MenuBarExtra {
            MenuBarView()
        } label: {
            let image = NSImage(resource: .appLogo)
            let size = NSSize(width: 22, height: 22)
            let resized = NSImage(size: size)
            
            let _ = {
                resized.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: size))
                resized.unlockFocus()
            }()
            
            Image(nsImage: resized)
        }
    }
}

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        Button("Settings") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Button("Support Author") {
            if let url = URL(string: "https://bufferfly.lemonsqueezy.com/checkout/buy/f2c0bafc-c7c7-4490-9e0b-80585135dadd") {
                NSWorkspace.shared.open(url)
            }
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
