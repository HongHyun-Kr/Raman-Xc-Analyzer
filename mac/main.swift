import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKUIDelegate, NSWindowDelegate {
    var window: NSWindow!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(self, name: "rxa")
        web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = self
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1500, height: 920),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Raman Xc Analyzer"
        window.contentView = web
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        if let dir = Bundle.main.resourceURL {
            let page = dir.appendingPathComponent("index.html")
            web.loadFileURL(page, allowingReadAccessTo: dir)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // Messages from the page: {cmd:'save', name, b64} or {cmd:'copy', b64}
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let d = m.body as? [String: Any],
              let cmd = d["cmd"] as? String,
              let b64 = d["b64"] as? String,
              let data = Data(base64Encoded: b64) else { return }
        if cmd == "copy" {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setData(data, forType: .png)
        } else if cmd == "save" {
            let p = NSSavePanel()
            p.nameFieldStringValue = (d["name"] as? String) ?? "export"
            p.beginSheetModal(for: window) { r in
                if r == .OK, let u = p.url { try? data.write(to: u) }
            }
        }
    }

    // File picker for <input type="file">
    func webView(_ w: WKWebView, runOpenPanelWith params: WKOpenPanelParameters,
                 initiatedByFrame f: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let p = NSOpenPanel()
        p.allowsMultipleSelection = params.allowsMultipleSelection
        p.canChooseDirectories = false
        p.begin { r in completionHandler(r == .OK ? p.urls : nil) }
    }

    func buildMenu() {
        let bar = NSMenu()
        let appItem = NSMenuItem(); bar.addItem(appItem)
        let app = NSMenu(); appItem.submenu = app
        app.addItem(withTitle: "Quit Raman Xc Analyzer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); bar.addItem(editItem)
        let edit = NSMenu(title: "Edit"); editItem.submenu = edit
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        NSApp.mainMenu = bar
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
