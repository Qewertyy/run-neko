// run-neko for macOS - Swift + AppKit
// Animates icons in macOS menu bar based on CPU usage with multiple runners and themes

import Cocoa
import Foundation
import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var icons: [NSImage] = []
    var currentIndex = 0
    var animationTimer: Timer?
    var cpuTimer: Timer?
    var cpuUsage: Float = 0.0

    var runner: String = "cat"
    var theme: String = "light"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(named: "light_cat_0")

        let menu = NSMenu()

        let runnerMenu = NSMenu(title: "Runner")
        for r in ["cat","parrot", "horse"] {
            let item = NSMenuItem(title: r.capitalized, action: #selector(setRunner(_:)), keyEquivalent: "")
            item.state = (r == runner) ? .on : .off
            item.representedObject = r
            runnerMenu.addItem(item)
        }

        let runnerItem = NSMenuItem(title: "Runner", action: nil, keyEquivalent: "")
        runnerItem.submenu = runnerMenu
        menu.addItem(runnerItem)

        let themeMenu = NSMenu(title: "Theme")
        for t in ["light", "dark"] {
            let item = NSMenuItem(title: t.capitalized, action: #selector(setTheme(_:)), keyEquivalent: "")
            item.state = (t == theme) ? .on : .off
            item.representedObject = t
            themeMenu.addItem(item)
        }

        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu

        loadIcons()
        startCPUTimer()
        startAnimation()
    }

    @objc func setRunner(_ sender: NSMenuItem) {
        guard let runnerValue = sender.representedObject as? String else { return }
        runner = runnerValue
        updateMenuStates()
        loadIcons()
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        guard let themeValue = sender.representedObject as? String else { return }
        theme = themeValue
        updateMenuStates()
        loadIcons()
    }

    func updateMenuStates() {
        guard let menuItems = statusItem.menu?.items else { return }

        for menuItem in menuItems {
            if let submenu = menuItem.submenu {
                for item in submenu.items {
                    if let val = item.representedObject as? String {
                        if menuItem.title == "Runner" {
                            item.state = (val == runner) ? .on : .off
                        } else if menuItem.title == "Theme" {
                            item.state = (val == theme) ? .on : .off
                        }
                    }
                }
            }
        }
    }


    func loadIcons() {
        icons = []
        let frames: Int = (runner == "cat") ? 5 : (runner == "parrot") ? 10 : 14
        for i in 0..<frames {
            if let icon = NSImage(named: "\(theme)_\(runner)_\(i)") {
                icon.isTemplate = false
                icons.append(icon)
            }
        }
        currentIndex = 0
    }

    func startCPUTimer() {
        cpuTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.cpuUsage = self.getCPUUsage()
        }
        cpuTimer?.tolerance = 0.2
    }

    func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            guard !self.icons.isEmpty else { return }
            self.statusItem.button?.image = self.icons[self.currentIndex]
            self.statusItem.button?.toolTip = String(format: "CPU Usage: %.1f%%", self.cpuUsage)
            self.currentIndex = (self.currentIndex + 1) % self.icons.count
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(self)
    }

    func getCPUUsage() -> Float {
        var kr: kern_return_t
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        var load = host_cpu_load_info()

        kr = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        if kr != KERN_SUCCESS {
            return -1
        }

        let user = Float(load.cpu_ticks.0)
        let sys = Float(load.cpu_ticks.1)
        let idle = Float(load.cpu_ticks.2)
        let nice = Float(load.cpu_ticks.3)

        let total = user + sys + idle + nice
        return (user + sys + nice) / total * 100.0
    }
}
