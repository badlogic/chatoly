import SwiftUI
import AppKit

@main
struct ChatolyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Chatoly") {
                    // Handle about action if needed
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app can become active
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Configure window after a brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            if let window = NSApplication.shared.windows.first {
                // Remove title bar and buttons
                window.styleMask = [.resizable, .fullSizeContentView, .borderless]
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                
                // Set floating behavior
                window.level = .floating
                window.isMovableByWindowBackground = true
                window.hasShadow = true
                
                // Make window appear on all spaces
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                
                // Activate window
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}