import SwiftUI
struct AboutSettingsView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 15) {
                    Image(.appLogo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.2))
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bufferfly").font(.headline)
                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Section("Links") {
                AboutLink(title: "Enjoy? Leave a star :)", iconName: "chevron.left.forwardslash.chevron.right", url: "https://github.com/thehaipe/Bufferfly")
                
                AboutLink(title: "Support Development", iconName: "heart.fill", url: "https://send.monobank.ua/jar/2qJmcYCUkW")
                
                AboutLink(title: "Report a Bug or Request a Feature", iconName: "exclamationmark.bubble.fill", url: "https://github.com/thehaipe/Bufferfly/issues")
                
                AboutLink(title: "Also Visit My LinkedIn", iconName: "briefcase.fill", url: "https://www.linkedin.com/in/valentyn-m-65a30b287")
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutLink: View {
    let title: String
    let iconName: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                
                Text(title)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(0.5)
            }
            .contentShape(Rectangle())
        }
    }
}

#Preview{
    AboutSettingsView()
}
