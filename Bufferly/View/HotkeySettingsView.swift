import SwiftUI
import Carbon

struct HotkeySettingsView: View {
    @State private var viewModel = HotkeySettingsViewModel()

    var body: some View {
        Form {
            Section {
                HStack {
                    // Current Keys Display
                    HStack(spacing: 5) {
                        ForEach(viewModel.modifierSymbols(), id: \.self) { symbol in
                             KeycapView(symbol: symbol)
                        }
                        KeycapView(symbol: viewModel.keyString())
                    }
                    .opacity(viewModel.isRecording ? 0.5 : 1.0)

                    Spacer()

                    Button {
                        viewModel.startRecording()
                    } label: {
                        Text(viewModel.isRecording ? "Waiting for key presses" : "Click to change")
                            .font(.subheadline)
                            .foregroundStyle(viewModel.isRecording ? .secondary : .primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewModel.isRecording ? Color.clear : Color.secondary.opacity(0.1))
                                    .stroke(viewModel.isRecording ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isRecording)
                }
                .padding(.vertical, 5)

                Text("Use this shortcut to summon Bufferly anywhere on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .background(KeyMonitor(
            isRecording: Binding(
                get: { viewModel.isRecording },
                set: { viewModel.isRecording = $0 }
            ),
            onKeyRecorded: { keyCode, modifiers in
                viewModel.registerHotKey(keyCode: keyCode, modifiers: modifiers)
            }
        ))
    }
}

// Hidden view to handle local event monitoring
struct KeyMonitor: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onKeyRecorded: (UInt32, UInt32) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.setup()
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        if isRecording {
            context.coordinator.start()
        } else {
            context.coordinator.stop()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        var parent: KeyMonitor
        var monitor: Any?

        init(_ parent: KeyMonitor) {
            self.parent = parent
        }

        func setup() {
            // Can be used for initial setup, mb it will be onboarding... idk rn
        }

        func start() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handle(event: event)
                return nil // Swallow the event so it doesn't type into other fields
            }
        }

        func stop() {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        func handle(event: NSEvent) {
            // Escape cancels recording
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    self.parent.isRecording = false
                }
                return
            }

            // Map NSEvent modifiers to Carbon modifiers
            let carbonModifiers = getCarbonModifiers(from: event.modifierFlags)
            let keyCode = UInt32(event.keyCode)

            DispatchQueue.main.async {
                self.parent.onKeyRecorded(keyCode, carbonModifiers)
            }
        }

        private func getCarbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
            var result: UInt32 = 0
            if flags.contains(.control) { result |= UInt32(controlKey) }
            if flags.contains(.option) { result |= UInt32(optionKey) }
            if flags.contains(.shift) { result |= UInt32(shiftKey) }
            if flags.contains(.command) { result |= UInt32(cmdKey) }
            return result
        }
    }
}
