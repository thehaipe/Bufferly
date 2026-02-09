import SwiftUI
import AppKit
import SwiftData
//MARK:Important note.
/*  I noticed that after my Mac came out of sleep mode, reusing Bufferfly became somewhat problematic. Since View was created once and simply reused, there were no problems with this until NSPanel started to become "stale." The decision was made to rebuild the view each time. The cost of this approach is not very expensive in terms of Bufferfly, but it eliminates other extremes from the stale state.
 */
@MainActor
final class OverlayWindowService {
    private var panel: NSPanel?
    private let container: ModelContainer
    private let pasteService: PasteService
    private var resignActiveObserver: NSObjectProtocol?

    init(container: ModelContainer, pasteService: PasteService) {
        self.container = container
        self.pasteService = pasteService
    }

    func toggleWindow() {
        if let panel = panel, panel.isVisible {
            closeWindow()
        } else {
            showWindow()
        }
    }

    func showWindow() {
        // Recreate panel each time for clean state
        panel?.orderOut(nil)
        panel = nil
        createPanel()

        guard let panel = panel else { return }

        let mouseLocation = NSEvent.mouseLocation
        let windowSize = panel.frame.size
        let screenFrame = NSScreen.main?.frame ?? .zero

        var x = mouseLocation.x - (windowSize.width / 2)
        var y = mouseLocation.y - (windowSize.height / 2)

        if x < screenFrame.minX { x = screenFrame.minX + 10 }
        if x + windowSize.width > screenFrame.maxX { x = screenFrame.maxX - windowSize.width - 10 }
        if y - windowSize.height < screenFrame.minY { y = screenFrame.minY + windowSize.height + 10 }

        panel.setFrameOrigin(NSPoint(x: x, y: y))

        // Hide any other windows (e.g. Settings) before activating,
        // otherwise NSApp.activate brings them back to front
        for window in NSApp.windows where window !== panel {
            window.orderOut(nil)
        }
        //Resolving the issue of RootView periodically appearing when pressing the shortcut.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        startMonitoringFocus()
    }

    func closeWindow() {
        panel?.orderOut(nil)
        stopMonitoringFocus()
        //Hide app to ensure focus returns to previous app immediately
        NSApp.hide(nil)
    }

    private func startMonitoringFocus() {
        stopMonitoringFocus()
        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeWindow()
        }
    }

    private func stopMonitoringFocus() {
        if let observer = resignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            resignActiveObserver = nil
        }
    }

    private func createPanel() {
        let viewModel = CarouselViewModel(pasteAction: { [weak self] item in
            self?.pasteService.paste(item: item)
        })

        let hostingController = NSHostingController(rootView:
            ClipboardCarouselView(viewModel: viewModel)
                .modelContainer(container)
        )

        // Remove .nonactivatingPanel to allow taking focus
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 338, height: 188),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hostingController
        panel.hidesOnDeactivate = true

        self.panel = panel
    }
}

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
