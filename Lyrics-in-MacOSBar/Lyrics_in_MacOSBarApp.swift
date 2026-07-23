//
//  LyricsOnMacOSBarApp.swift
//  Lyrics-in-MacOSBar
//
//  Created by 何旺霖 on 2026/5/14.
//

import SwiftUI
import AppKit

@main
struct LyricsOnMacOSBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    let monitor = MusicMonitor.shared
    let lyricManager = LyricManager()
    
    var eventMonitor: Any?
    
    // ⚠️ 核心修复：保持对关于窗口的强引用，防止被 ARC 误杀引发 EXC_BAD_ACCESS 崩溃
    var aboutWindow: NSWindow?
    override init() {
            super.init()
            AppDelegate.shared = self
        }

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView(musicMonitor: monitor, lyricManager: lyricManager)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = false
        
        if let btn = statusItem.button {
            btn.action = #selector(togglePopover(_:))
            btn.target = self
            btn.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
            btn.imagePosition = .imageLeft
        }

        monitor.onStateChange = { [weak self] isPlaying, lyric in
            self?.updateMenuBar(isPlaying: isPlaying, lyric: lyric)
        }
    }

    func updateMenuBar(isPlaying: Bool, lyric: String) {
        if isPlaying {
            if let btn = statusItem.button {
                if btn.title != lyric {
                    btn.title = lyric
                }
            }
            if !statusItem.isVisible {
                statusItem.isVisible = true
            }
        } else {
            if statusItem.isVisible {
                statusItem.isVisible = false
            }
            if popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func showPopover(sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        
        if eventMonitor == nil {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let popover = self?.popover, popover.isShown {
                    self?.closePopover(sender: event)
                }
            }
        }
    }
        
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    // 🌟 创建并管理独立悬浮窗
    func showAboutWindow() {
        if aboutWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            window.title = "About LyricsOnMacOSBar"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            // ⚠️ 核心修复：明确告知系统关闭时不要销毁实例，由我们自己管理内存
            window.isReleasedWhenClosed = false
            
            let hostingController = NSHostingController(rootView: AboutView())
            window.contentViewController = hostingController
            window.center()
            
            self.aboutWindow = window
        }
        
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct MenuContentView: View {
    @ObservedObject var musicMonitor: MusicMonitor
    let lyricManager: LyricManager
    
    @State private var inputUserToken: String = UserDefaults.standard.string(forKey: "AppleMusicMediaUserToken") ?? ""
    @State private var inputDevToken: String = UserDefaults.standard.string(forKey: "AppleMusicDeveloperToken") ?? ""
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Menu("当前歌词源: \(musicMonitor.selectedSource.rawValue)") {
                ForEach(LyricSourceConfig.allCases, id: \.self) { source in
                    Button(action: {
                        musicMonitor.selectedSource = source
                        musicMonitor.reFetchLyrics()
                    }) {
                        Text(musicMonitor.selectedSource == source ? "✓ \(source.rawValue)" : "   \(source.rawValue)")
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)
            
            Divider()
            
            HStack(spacing: 40) {
                Button(action: { musicMonitor.previousTrack() }) {
                    Image(systemName: "backward.fill").font(.system(size: 18))
                }.buttonStyle(.plain)
                
                Button(action: { musicMonitor.togglePlayPause() }) {
                    Image(systemName: musicMonitor.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                }.buttonStyle(.plain)
                
                Button(action: { musicMonitor.nextTrack() }) {
                    Image(systemName: "forward.fill").font(.system(size: 18))
                }.buttonStyle(.plain)
            }
            .padding(.vertical, 16)
            
            Divider()
            
            // ⚠️ 恢复：双 Token 设置区域保留在主菜单中
            VStack(alignment: .leading, spacing: 8) {
                Button(action: { showSettings.toggle() }) {
                    HStack {
                        Text("Apple Music 接口凭证设置")
                        Spacer()
                        Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 16, alignment: .center)
                            .animation(nil, value: showSettings)
                    }
                    .padding(.vertical, 6).padding(.horizontal, 16).contentShape(Rectangle())
                }.buttonStyle(.plain)

                if showSettings {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Developer Token (基础鉴权凭证):")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("留空则使用内置默认凭证...", text: $inputDevToken)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 10))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("media-user-token (解锁动态逐字歌词):")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("粘贴会员 Token 到这里...", text: $inputUserToken)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 10))
                        }
                        
                        Button(action: {
                            UserDefaults.standard.set(inputDevToken, forKey: "AppleMusicDeveloperToken")
                            UserDefaults.standard.set(inputUserToken, forKey: "AppleMusicMediaUserToken")
                            musicMonitor.reFetchLyrics()
                            
                            let haptic = NSHapticFeedbackManager.defaultPerformer
                            haptic.perform(.generic, performanceTime: .now)
                            showSettings = false
                        }) {
                            Text("保存并应用")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            
            Divider()
            
            VStack(spacing: 4) {
                Button(action: { NSWorkspace.shared.open(lyricManager.localFolderURL) }) {
                    HStack { Text("打开本地歌词文件夹"); Spacer() }
                    .padding(.vertical, 6).padding(.horizontal, 16).contentShape(Rectangle())
                }.buttonStyle(.plain)
                
                Button(action: {
                    AppDelegate.shared.showAboutWindow()
                    AppDelegate.shared.closePopover(sender: nil)
                }) {
                    HStack { Text("关于 LyricsOnMacOSBar"); Spacer() }
                    .padding(.vertical, 6).padding(.horizontal, 16).contentShape(Rectangle())
                }.buttonStyle(.plain)
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack { Text("退出"); Spacer() }
                    .padding(.vertical, 6).padding(.horizontal, 16).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }
}
