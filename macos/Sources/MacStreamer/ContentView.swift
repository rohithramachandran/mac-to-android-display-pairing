import SwiftUI

// MARK: - Colour Palette
extension Color {
    static let bg        = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let sidebar   = Color(red: 0.08, green: 0.09, blue: 0.13)
    static let card      = Color(red: 0.11, green: 0.13, blue: 0.18)
    static let border    = Color(red: 0.20, green: 0.22, blue: 0.28)
    static let accent    = Color(red: 0.18, green: 0.51, blue: 0.97)
    static let good      = Color(red: 0.25, green: 0.73, blue: 0.32)
    static let warn      = Color(red: 0.82, green: 0.60, blue: 0.13)
    static let bad       = Color(red: 0.97, green: 0.32, blue: 0.29)
    static let dim       = Color(red: 0.50, green: 0.53, blue: 0.60)
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var manager: StreamManager

    var body: some View {
        VSplitView {
            // ── Top: sidebar + settings ──────────────────────────────────
            HStack(spacing: 0) {
                SidebarView()
                    .frame(width: 260)
                Divider().background(Color.border)
                ConfigView()
            }
            .frame(minHeight: 480)

            // ── Bottom: log console ──────────────────────────────────────
            LogConsoleView()
                .frame(minHeight: 160)
        }
        .background(Color.bg)
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var manager: StreamManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "display.2")
                    .font(.title2).foregroundColor(.accent)
                Text("MacStreamer")
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().background(Color.border).padding(.horizontal, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // ── Devices ──────────────────────────────────────────
                    SidebarSection(title: "Devices") {
                        if manager.connectedDevices.isEmpty {
                            Label("No device connected", systemImage: "cable.connector.slash")
                                .font(.caption)
                                .foregroundColor(.dim)
                        } else {
                            ForEach(manager.connectedDevices, id: \.self) { d in
                                Label(d, systemImage: "iphone")
                                    .font(.caption)
                                    .foregroundColor(.good)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        Button(action: { manager.refreshDevices() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accent)
                    }

                    // ── Tools ─────────────────────────────────────────────
                    SidebarSection(title: "Tools") {
                        ToolRow(name: "adb",    path: manager.adbPath)
                        ToolRow(name: "ffmpeg", path: manager.ffmpegPath)
                    }

                    // ── Status ────────────────────────────────────────────
                    SidebarSection(title: "Status") {
                        StatusBadge(manager: manager)
                    }
                }
                .padding(12)
            }

            Spacer()

            // ── Action Button ─────────────────────────────────────────────
            VStack(spacing: 8) {
                Divider().background(Color.border)
                if manager.isSettingUp {
                    HStack {
                        ProgressView().scaleEffect(0.7)
                        Text("Setting up…").foregroundColor(.dim).font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else if manager.isStreaming {
                    StreamButton(label: "Stop Streaming",
                                 icon: "stop.fill",
                                 color: .bad) { manager.stopStreaming() }
                } else {
                    StreamButton(label: "Start Streaming",
                                 icon: "play.fill",
                                 color: .accent) { manager.startStreaming() }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .background(Color.sidebar)
    }
}

// MARK: - Config View
struct ConfigView: View {
    @EnvironmentObject var manager: StreamManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Stream Configuration")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    .padding(.bottom, 4)

                // Connection
                ConfigSection(title: "Connection", icon: "network") {
                    ConfigField(label: "Port", hint: "5000",
                                value: $manager.port,
                                help: "TCP port used for ADB forwarding")
                    ConfigField(label: "APK Path", hint: "Optional path to .apk",
                                value: $manager.apkPath,
                                help: "If set, installs APK before streaming") {
                        apkBrowseButton
                    }
                }

                // Display
                ConfigSection(title: "Display", icon: "rectangle.on.rectangle") {
                    HStack(alignment: .bottom, spacing: 10) {
                        ConfigField(label: "Display Index", hint: "e.g. 6",
                                    value: $manager.displayIndex,
                                    help: "AVFoundation capture device index")
                        Button(action: { manager.listDisplays() }) {
                            Label("List Displays", systemImage: "list.bullet")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.card)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accent)
                        .padding(.bottom, 1)
                    }
                    HStack(spacing: 10) {
                        ConfigField(label: "Width",  hint: "1920", value: $manager.resWidth)
                        Text("×").foregroundColor(.dim).padding(.bottom, 1)
                        ConfigField(label: "Height", hint: "1080", value: $manager.resHeight)
                    }
                }

                // Encoding
                ConfigSection(title: "Encoding", icon: "waveform") {
                    HStack(spacing: 12) {
                        ConfigField(label: "Frame Rate", hint: "60",  value: $manager.framerate,
                                    help: "FPS (e.g. 30, 60)")
                        ConfigField(label: "Bitrate",    hint: "6M",  value: $manager.bitrate,
                                    help: "Video bitrate (e.g. 4M, 8M)")
                        ConfigField(label: "Probe Size", hint: "5M", value: $manager.probesize,
                                    help: "FFmpeg probesize")
                    }
                }
            }
            .padding(24)
        }
        .background(Color.bg)
    }

    // APK file picker
    var apkBrowseButton: some View {
        Button(action: openApkPicker) {
            Image(systemName: "folder")
                .foregroundColor(.accent)
        }
        .buttonStyle(.plain)
    }

    private func openApkPicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "apk")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            manager.apkPath = url.path
        }
    }
}

// MARK: - Log Console
struct LogConsoleView: View {
    @EnvironmentObject var manager: StreamManager
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            // Bar
            HStack {
                Image(systemName: "terminal.fill").foregroundColor(.dim).font(.caption)
                Text("Output Log").font(.caption).foregroundColor(.dim)
                Spacer()
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundColor(.dim)
                Button("Clear") { manager.clearLogs() }
                    .font(.caption)
                    .foregroundColor(.dim)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.sidebar)

            Divider().background(Color.border)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(manager.logs) { entry in
                            LogRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: manager.logs.count) { _ in
                    if autoScroll, let last = manager.logs.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(red: 0.04, green: 0.05, blue: 0.07))
    }
}

// MARK: - Log Row
struct LogRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(timeStr)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.dim)
                .frame(width: 58, alignment: .leading)
            Text(entry.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(msgColor)
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var timeStr: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
        return f.string(from: entry.timestamp)
    }

    private var msgColor: Color {
        switch entry.level {
        case .success: return .good
        case .warning: return .warn
        case .error:   return .bad
        default:       return Color(red: 0.78, green: 0.82, blue: 0.88)
        }
    }
}

// MARK: - Helper Views

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.dim)
                .tracking(1.2)
            content()
        }
    }
}

struct ToolRow: View {
    let name: String
    let path: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(path.isEmpty ? Color.bad : Color.good)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.caption)
                .foregroundColor(path.isEmpty ? .dim : .white)
            Spacer()
            if !path.isEmpty {
                Text((path as NSString).lastPathComponent)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.dim)
            } else {
                Text("not found").font(.caption2).foregroundColor(.bad)
            }
        }
    }
}

struct StatusBadge: View {
    @ObservedObject var manager: StreamManager
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.8), radius: pulse ? 6 : 2)
                .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
                .onAppear { pulse = true }
            Text(statusLabel)
                .font(.caption)
                .foregroundColor(statusColor)
        }
    }

    private var statusColor: Color {
        if manager.isStreaming { return .good }
        if manager.isSettingUp { return .warn }
        return .dim
    }

    private var statusLabel: String {
        if manager.isStreaming { return "Streaming" }
        if manager.isSettingUp { return "Setting up…" }
        return "Idle"
    }
}

struct StreamButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    hovering
                        ? color.opacity(0.85)
                        : color.opacity(0.15)
                )
                .foregroundColor(hovering ? .white : color)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.5)))
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}

struct ConfigSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundColor(.accent)
                Text(title).font(.caption).fontWeight(.semibold)
                    .foregroundColor(.dim).tracking(1)
                    .textCase(.uppercase)
            }
            content()
                .padding(14)
                .background(Color.card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 1))
        }
    }
}

struct ConfigField<Accessory: View>: View {
    let label: String
    let hint: String
    @Binding var value: String
    var help: String? = nil
    @ViewBuilder var accessory: () -> Accessory

    init(label: String, hint: String, value: Binding<String>,
         help: String? = nil, @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
        self.label = label
        self.hint = hint
        self._value = value
        self.help = help
        self.accessory = accessory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.dim)
            HStack(spacing: 6) {
                TextField(hint, text: $value)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.bg)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.border))
                accessory()
            }
            if let h = help {
                Text(h).font(.system(size: 10)).foregroundColor(.dim)
            }
        }
    }
}
