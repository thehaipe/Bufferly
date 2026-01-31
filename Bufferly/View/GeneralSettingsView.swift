import SwiftUI
import SwiftData
import ApplicationServices
internal import Combine

struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearAlert = false
    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }
            
            Section("Permissions") {
                HStack(spacing: 12) {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(isAccessibilityTrusted ? .green : .red)
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading) {
                        Text("Accessibility Access")
                            .font(.headline)
                        Text(isAccessibilityTrusted ? "Bufferly has full access to work properly." : "Required for overlay and shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !isAccessibilityTrusted {
                        Button("Enable") {
                            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                            AXIsProcessTrustedWithOptions(options)
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onReceive(timer) { _ in
                isAccessibilityTrusted = AXIsProcessTrusted()
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Limit")
                        Spacer()
                        Text("\(historyLimit) items")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(historyLimit) },
                        set: { historyLimit = Int($0) }
                    ), in: 10...50, step: 5)
                }
                
                if historyLimit >= 45  {
                    Text("⚠️ Higher limits may impact performance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Text("Clear Clipboard History")
                }
                .alert("Are you sure?", isPresented: $showingClearAlert) {
                    Button("Clear", role: .destructive) {
                        do { try modelContext.delete(model: ClipboardItem.self) } catch {}
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This action cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
    }
}
