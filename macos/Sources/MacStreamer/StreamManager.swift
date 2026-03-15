import Foundation
import Combine

// MARK: - Log Model
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel

    enum LogLevel { case info, success, warning, error }
}

// MARK: - StreamManager
class StreamManager: ObservableObject {

    // MARK: Configuration
    @Published var port: String = "5000"
    @Published var displayIndex: String = "6"
    @Published var framerate: String = "60"
    @Published var bitrate: String = "6M"
    @Published var resWidth: String = "1920"
    @Published var resHeight: String = "1080"
    @Published var probesize: String = "5M"
    @Published var apkPath: String = ""

    // MARK: State
    @Published var isStreaming: Bool = false
    @Published var isSettingUp: Bool = false
    @Published var logs: [LogEntry] = []
    @Published var connectedDevices: [String] = []
    @Published var adbPath: String = ""
    @Published var ffmpegPath: String = ""

    private var ffmpegProcess: Process?
    private var deviceTimer: Timer?

    init() {
        adbPath  = findTool("adb")
        ffmpegPath = findTool("ffmpeg")
        if adbPath.isEmpty  { addLog("⚠️ adb not found. Install: brew install --cask android-platform-tools", level: .warning) }
        if ffmpegPath.isEmpty { addLog("⚠️ ffmpeg not found. Install: brew install ffmpeg", level: .warning) }
        startDeviceMonitoring()
    }

    // MARK: - Tool Discovery
    private func findTool(_ name: String) -> String {
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/opt/local/bin/\(name)"
        ]
        for p in candidates where FileManager.default.isExecutableFile(atPath: p) { return p }

        // Fallback: `which`
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = [name]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run(); proc.waitUntilExit()
        let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return FileManager.default.isExecutableFile(atPath: result) ? result : ""
    }

    // MARK: - Device Monitoring
    private func startDeviceMonitoring() {
        deviceTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.refreshDevices()
        }
        refreshDevices()
    }

    func refreshDevices() {
        guard !adbPath.isEmpty else { return }
        Task.detached { [weak self] in
            guard let self else { return }
            let output = self.runSync(self.adbPath, args: ["devices"])
            let devices = output.components(separatedBy: "\n")
                .dropFirst()
                .filter { $0.contains("\tdevice") }
                .map { String($0.split(separator: "\t").first ?? "") }
                .filter { !$0.isEmpty }

            await MainActor.run {
                let changed = devices != self.connectedDevices
                self.connectedDevices = devices
                if changed && !devices.isEmpty {
                    self.addLog("📱 Device connected: \(devices.joined(separator: ", "))", level: .success)
                }
            }
        }
    }

    // MARK: - List Displays
    func listDisplays() {
        guard !ffmpegPath.isEmpty else { addLog("ffmpeg not found", level: .error); return }
        addLog("🖥 Listing AVFoundation devices…", level: .info)
        Task.detached { [weak self] in
            guard let self else { return }
            let out = self.runSync(self.ffmpegPath,
                                  args: ["-f", "avfoundation", "-list_devices", "true", "-i", ""],
                                  captureStderr: true)
            let lines = out.components(separatedBy: "\n").filter { $0.lowercased().contains("screen") || $0.lowercased().contains("capture") || $0.contains("[") }
            await MainActor.run {
                for l in lines { self.addLog(l, level: .info) }
            }
        }
    }

    // MARK: - Start / Stop
    func startStreaming() {
        guard !isStreaming, !isSettingUp else { return }
        guard !connectedDevices.isEmpty else { addLog("❌ No Android device connected", level: .error); return }
        isSettingUp = true
        addLog("🚀 Setting up stream…", level: .info)

        Task.detached { [weak self] in
            guard let self else { return }

            // 1. ADB forward
            await MainActor.run { self.addLog("📡 ADB port forwarding tcp:\(self.port)…", level: .info) }
            let fwd = self.runSync(self.adbPath, args: ["forward", "tcp:\(self.port)", "tcp:\(self.port)"])
            if fwd.lowercased().contains("error") {
                await MainActor.run {
                    self.addLog("❌ ADB forward failed: \(fwd)", level: .error)
                    self.isSettingUp = false
                }
                return
            }
            await MainActor.run { self.addLog("✅ Port forwarding OK", level: .success) }

            // 2. Install APK
            let apk = await MainActor.run { self.apkPath }
            if !apk.isEmpty && FileManager.default.fileExists(atPath: apk) {
                await MainActor.run { self.addLog("📦 Installing APK…", level: .info) }
                let inst = self.runSync(self.adbPath, args: ["install", "-r", "-d", apk])
                await MainActor.run { self.addLog(inst.isEmpty ? "✅ APK installed" : inst, level: .info) }
            }

            // 3. Start Android app
            await MainActor.run { self.addLog("📱 Launching MacDisplay on device…", level: .info) }
            _ = self.runSync(self.adbPath, args: ["shell", "am", "start", "-n", "com.macdisplay.app/.MainActivity"])

            // 4. Wait for app init
            await MainActor.run { self.addLog("⏳ Waiting 3s for app to initialize…", level: .info) }
            try? await Task.sleep(nanoseconds: 3_000_000_000)

            // 5. Launch ffmpeg
            await MainActor.run {
                self.isSettingUp = false
                self.isStreaming = true
                self.addLog("🎬 Starting ffmpeg…", level: .info)
            }
            await self.launchFfmpeg()
        }
    }

    func stopStreaming() {
        addLog("🛑 Stopping stream…", level: .warning)
        ffmpegProcess?.terminate()
        ffmpegProcess = nil
        isStreaming = false
        isSettingUp = false
        Task.detached { [weak self] in
            guard let self else { return }
            _ = self.runSync(self.adbPath, args: ["forward", "--remove", "tcp:\(self.port)"])
            await MainActor.run { self.addLog("🧹 Cleaned up port forward", level: .info) }
        }
    }

    // MARK: - FFmpeg
    private func launchFfmpeg() async {
        let idx = await MainActor.run { self.displayIndex }
        let fps = await MainActor.run { self.framerate }
        let br  = await MainActor.run { self.bitrate }
        let w   = await MainActor.run { self.resWidth }
        let h   = await MainActor.run { self.resHeight }
        let pb  = await MainActor.run { self.probesize }
        let pt  = await MainActor.run { self.port }

        let args: [String] = [
            "-fflags", "nobuffer", "-flags", "low_delay",
            "-f", "avfoundation",
            "-pix_fmt", "uyvy422",
            "-probesize", pb,
            "-capture_cursor", "1",
            "-framerate", fps,
            "-i", idx,
            "-vf", "scale=\(w):\(h),format=yuv420p",
            "-r", fps,
            "-c:v", "h264_videotoolbox",
            "-profile:v", "baseline",
            "-realtime", "1",
            "-bf", "0",
            "-g", fps,
            "-b:v", br,
            "-f", "h264",
            "tcp://127.0.0.1:\(pt)"
        ]

        await MainActor.run { self.addLog("▶ ffmpeg " + args.joined(separator: " "), level: .info) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError  = pipe

        await MainActor.run { self.ffmpegProcess = process }

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self else { return }
            let text = String(data: data, encoding: .utf8) ?? ""
            let lines = text
                .components(separatedBy: .init(charactersIn: "\r\n"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            DispatchQueue.main.async {
                for line in lines {
                    // Reuse last log entry for ffmpeg frame= progress lines
                    if line.hasPrefix("frame="), let last = self.logs.last, last.message.hasPrefix("frame=") {
                        self.logs[self.logs.count - 1] = LogEntry(timestamp: Date(), message: line, level: .info)
                    } else {
                        self.addLog(line, level: .info)
                    }
                }
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            await MainActor.run { self.addLog("❌ ffmpeg failed: \(error.localizedDescription)", level: .error) }
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        await MainActor.run {
            self.isStreaming = false
            self.addLog("🛑 Stream ended (exit \(process.terminationStatus))", level: .warning)
            _ = self.runSync(self.adbPath, args: ["forward", "--remove", "tcp:\(self.port)"])
        }
    }

    // MARK: - Sync Helper
    func runSync(_ path: String, args: [String], captureStderr: Bool = false) -> String {
        guard !path.isEmpty else { return "" }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        if captureStderr { p.standardError = pipe }
        do {
            try p.run(); p.waitUntilExit()
        } catch { return "Error: \(error)" }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    // MARK: - Log
    func addLog(_ msg: String, level: LogEntry.LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), message: msg, level: level)
        DispatchQueue.main.async {
            self.logs.append(entry)
            if self.logs.count > 2000 { self.logs.removeFirst(self.logs.count - 2000) }
        }
    }

    func clearLogs() { logs.removeAll() }

    deinit { deviceTimer?.invalidate(); ffmpegProcess?.terminate() }
}
