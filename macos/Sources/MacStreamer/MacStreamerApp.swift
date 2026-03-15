import SwiftUI

@main
struct MacStreamerApp: App {
    @StateObject private var manager = StreamManager()

    var body: some Scene {
        WindowGroup("Mac Display Streamer") {
            ContentView()
                .environmentObject(manager)
                .frame(minWidth: 900, idealWidth: 980, minHeight: 680, idealHeight: 740)
                .preferredColorScheme(.dark)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
