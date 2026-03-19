import SwiftUI

@main
struct CtxMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 600, height: 480)
    }
}
