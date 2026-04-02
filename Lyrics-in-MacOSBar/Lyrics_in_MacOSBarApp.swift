import SwiftUI
import AppKit

@main
struct LyricsOnMacOSBarApp: App {
    @StateObject var musicMonitor = MusicMonitor()
    let lyricManager = LyricManager()

    var body: some Scene {
        MenuBarExtra {
            // 当我们开启 .window 模式后，这里就是一个可以完全自由排版的画布了
            VStack(spacing: 0) {
                
                // 1. 顶部留白和歌词源切换
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                
                // 2. 真正的完美横向控制条！
                HStack(spacing: 40) { // 调整间距让按钮更舒展
                    Button(action: {
                        musicMonitor.previousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain) // 去除原生背景
                    
                    Button(action: {
                        musicMonitor.togglePlayPause()
                    }) {
                        Image(systemName: musicMonitor.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24)) // 播放键大一点
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        musicMonitor.nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 16) // 上下留出呼吸感
                
                Divider()
                
                // 3. 底部功能区 (需要手动用 HStack 撑开宽度，模仿菜单的点击感)
                VStack(spacing: 4) {
                    Button(action: {
                        NSWorkspace.shared.open(lyricManager.localFolderURL)
                    }) {
                        HStack {
                            Text("打开本地歌词文件夹")
                            Spacer() // 把文字推到左边
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle()) // 让整行都可以点击
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showAboutWindow()
                    }) {
                        HStack {
                            Text("关于 LyricsOnMacOSBar")
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack {
                            Text("退出")
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
            .frame(width: 260) // 固定面板宽度，看起来更像一个标准的小组件
            
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "music.note")
                Text(musicMonitor.currentLyricLine)
                    .font(.system(size: 14, weight: .regular, design: .default))
            }
        }
        // ⚠️ 终极魔法：告诉系统不要用死板的下拉列表，用带有毛玻璃效果的独立面板！
        .menuBarExtraStyle(.window)
    }
    
    // ... 下面的 showAboutWindow() 方法代码保持不变，不要删掉哦！ ...
    private func showAboutWindow() {
        let alert = NSAlert()
        if let appIcon = NSImage(named: "AppIcon") { alert.icon = appIcon }
        alert.messageText = "关于 LyricsOnMacOSBar"
        alert.informativeText = "开发者: motian566\n\n【开源与免费声明】\n本软件为 GitHub 上的开源免费项目，代码完全公开。严禁任何个人或组织将本软件用于商业牟利、二次打包或倒卖行为。\n仓库地址：https://github.com/motian566/LyricsOnMacOSBar\n\n【免责声明】\n本软件仅作个人编程学习与技术交流使用。软件本身不提供、不存储任何音乐资源。作者不对使用本软件抓取网络歌词的数据准确性、潜在的版权纠纷，以及由此引发的任何直接或间接损失承担法律责任。"
        alert.addButton(withTitle: "我知道了")
        alert.addButton(withTitle: "访问 GitHub 主页")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/motian566/LyricsOnMacOSBar") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
