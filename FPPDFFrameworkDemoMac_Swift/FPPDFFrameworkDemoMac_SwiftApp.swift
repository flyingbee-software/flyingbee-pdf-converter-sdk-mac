//
//  FPPDFFrameworkDemoMac_SwiftApp.swift
//  FPPDFFrameworkDemoMac_Swift
//
//  SwiftUI application entry point.
//
//  Created by James Wei on 9/4/26.
//  Copyright (c) 2026 Flyingbee Software. All rights reserved.
//

import SwiftUI

@main
struct FPPDFFrameworkDemoMac_SwiftApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = ConverterViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(width: 760, height: 612)
        }
        // Force the window to the same size as the Objective-C demo (~800 x 644
        // including the title bar). If the content genuinely needs more room the
        // window grows slightly rather than clipping anything.
        .defaultSize(width: 800, height: 644)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// Application delegate keeping the Objective-C demo's lifecycle behaviour:
/// terminate when the last window closes, restore persisted locations on launch,
/// and release security-scoped resources on quit.
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let viewModel = ConverterViewModel.shared

        // Restore after the current run-loop turn: these calls publish changes
        // to observed @Published properties, and doing it synchronously here can
        // happen while SwiftUI is building its first views, which logs
        // "Publishing changes from within view updates is not allowed".
        DispatchQueue.main.async {
            viewModel.restoreBookmarkedFiles()
            viewModel.restoreOutputDirectory()
            NSApp.windows.first?.title = "Flyingbee PDF Converter (SwiftUI)"
        }

        // The Objective-C demo's window is ~800 x 644. SwiftUI sizes a
        // WindowGroup window from the content's ideal size, which here is larger
        // than desired, so the size is set explicitly on the NSWindow instead.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard let window = NSApp.windows.first(where: { $0.canBecomeMain }) ?? NSApp.windows.first else { return }
            var frame = window.frame
            frame.size = NSSize(width: 800, height: 644)
            window.setFrame(frame, display: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        ConverterViewModel.shared.saveSettings()
        ConverterViewModel.shared.releaseSecurityScopedResources()
    }
}
