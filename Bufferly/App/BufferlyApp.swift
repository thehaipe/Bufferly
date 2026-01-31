import SwiftUI
import SwiftData
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardService: ClipboardService?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and App Switcher
        NSApp.setActivationPolicy(.accessory)
        
        let container = BufferlyApp.columnModelContainer
        
        // Setup Clipboard Service
        let service = ClipboardService(container: container)
        service.startMonitoring()
        self.clipboardService = service
        
        // Setup Overlay Service
        OverlayWindowService.shared.setup(with: container)
        
        // Setup Hotkeys
        setupHotkeys()
    }
    
    private func setupHotkeys() {
        // Init service and register saved/default hotkey
        HotKeyService.shared.register()
        
        HotKeyService.shared.onHotKeyTriggered = {
            Task { @MainActor in
                OverlayWindowService.shared.toggleWindow()
            }
        }
    }
}

@main
struct BufferlyApp: App {
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
            SettingsLink {
                Text("Settings")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button("Support Author") {
                if let url = URL(string: "https://github.com/sponsors/valentyn") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
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
