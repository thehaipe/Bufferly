import SwiftUI
import SwiftData
internal import Combine

struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GeneralSettingsViewModel()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }

            Section("Permissions") {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isAccessibilityTrusted ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(viewModel.isAccessibilityTrusted ? .green : .red)
                        .font(.system(size: 18))

                    VStack(alignment: .leading) {
                        Text("Accessibility Access")
                            .font(.headline)
                        Text(viewModel.isAccessibilityTrusted ? "Bufferfly has full access to work properly." : "Required for overlay and shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !viewModel.isAccessibilityTrusted {
                        Button("Enable") {
                            viewModel.requestAccessibilityAccess()
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onReceive(timer) { _ in
                viewModel.refreshAccessibilityStatus()
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
        }
        .formStyle(.grouped)
    }
}
