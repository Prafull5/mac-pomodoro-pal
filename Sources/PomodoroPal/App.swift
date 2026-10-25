import AppKit
import SwiftUI
import Combine

@MainActor
final class PomodoroAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let timer = TimerStore()
    private var dashboard: NSWindow!
    private var companion: NSPanel!
    private var announcement: NSPanel!
    private var statusItem: NSStatusItem!
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        makeDashboard()
        makeCompanion()
        makeAnnouncement()
        makeStatusItem()

        timer.$overlay
            .receive(on: RunLoop.main)
            .sink { [weak self] overlay in
                guard let self else { return }
                if overlay == nil {
                    self.announcement.orderOut(nil)
                } else {
                    self.announcement.center()
                    self.announcement.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest3(timer.$phase, timer.$secondsRemaining, timer.$isPaused)
            .receive(on: RunLoop.main)
            .sink { [weak self] phase, _, paused in
                guard let self else { return }
                let symbol = phase == .focus ? "◉" : phase == .breakTime ? "☕" : "✦"
                self.statusItem.button?.title = "\(symbol) \(phase == .ready || phase == .breakFinished ? "Pal" : self.timer.timeString)\(paused ? " Ⅱ" : "")"
            }
            .store(in: &subscriptions)

        dashboard.makeKeyAndOrderFront(nil)
        companion.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func makeDashboard() {
        dashboard = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        dashboard.title = "Pomodoro Pal"
        dashboard.titlebarAppearsTransparent = true
        dashboard.isMovableByWindowBackground = true
        dashboard.center()
        dashboard.contentView = NSHostingView(rootView: DashboardView(timer: timer))
    }

    private func makeCompanion() {
        companion = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 185, height: 90),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        companion.isOpaque = false
        companion.backgroundColor = .clear
        companion.hasShadow = false
        companion.level = .floating
        companion.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        companion.isMovableByWindowBackground = true
        companion.hidesOnDeactivate = false
        companion.contentView = NSHostingView(rootView: FloatingView(timer: timer) { [weak self] in self?.openDashboard() })
        if let visibleFrame = NSScreen.main?.visibleFrame {
            companion.setFrameOrigin(NSPoint(x: visibleFrame.maxX - 210, y: visibleFrame.maxY - 120))
        }
    }

    private func makeAnnouncement() {
        announcement = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 470),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        announcement.isOpaque = false
        announcement.backgroundColor = .clear
        announcement.hasShadow = true
        announcement.level = .statusBar
        announcement.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        announcement.hidesOnDeactivate = false
        announcement.contentView = NSHostingView(rootView: OverlayView(timer: timer) { [weak self] in self?.openDashboard() })
    }

    private func makeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "✦ Pal"
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Open Pomodoro Pal", action: #selector(openDashboardFromMenu), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Start focus", action: #selector(startFocusFromMenu), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Pause / Resume", action: #selector(togglePauseFromMenu), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Reset timer", action: #selector(resetFromMenu), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pomodoro Pal", action: #selector(quitFromMenu), keyEquivalent: "q"))
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.item(at: 1)?.isEnabled = timer.phase == .ready || timer.phase == .breakFinished
        menu.item(at: 2)?.isEnabled = timer.phase == .focus || timer.phase == .breakTime
        menu.item(at: 2)?.title = timer.isPaused ? "Resume timer" : "Pause timer"
        menu.item(at: 3)?.isEnabled = timer.phase != .ready
    }

    private func openDashboard() {
        dashboard.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openDashboardFromMenu() { openDashboard() }
    @objc private func startFocusFromMenu() { timer.startFocus() }
    @objc private func togglePauseFromMenu() { timer.togglePause() }
    @objc private func resetFromMenu() { timer.reset() }
    @objc private func quitFromMenu() { NSApp.terminate(nil) }
}

@main
struct PomodoroPalMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = PomodoroAppDelegate()
        app.delegate = delegate
        app.run()
    }
}
