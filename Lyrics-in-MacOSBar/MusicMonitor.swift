import Foundation
import Combine

class MusicMonitor: ObservableObject {
    @Published var currentLyricLine: String = "打开 Apple Music 听点什么吧"
    @Published var selectedSource: LyricSourceConfig = .auto
    
    // --- 新增：专门记录当前的播放状态 ---
    @Published var isPlaying: Bool = false
    
    private var currentTrackName: String = ""
    private var currentArtistName: String = ""
    private var currentLyrics: [ParsedLyricLine] = []
    private let lyricManager = LyricManager()
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    func reFetchLyrics() {
        guard !currentTrackName.isEmpty, !currentArtistName.isEmpty else { return }
        
        Task {
            let fetchedLyrics = await self.lyricManager.fetchLyrics(
                trackName: self.currentTrackName,
                artistName: self.currentArtistName,
                sourceConfig: self.selectedSource
            ) { statusText in
                DispatchQueue.main.async {
                    self.currentLyricLine = statusText
                }
            }
            
            DispatchQueue.main.async {
                self.currentLyrics = fetchedLyrics
                if fetchedLyrics.isEmpty {
                    self.currentLyricLine = "\(self.currentTrackName) (未在\(self.selectedSource.rawValue)找到)"
                }
            }
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.fetchCurrentTrackInfo()
        }
    }
    
    func fetchCurrentTrackInfo() {
        // --- 修改：让 AppleScript 精准返回 playing 还是 paused ---
        let scriptSource = """
        tell application "Music"
            if it is running then
                set pState to "stopped"
                if player state is playing then set pState to "playing"
                if player state is paused then set pState to "paused"
                
                if pState is not "stopped" then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackTime to player position
                    -- 把状态作为第 4 个参数拼在最后返回
                    return trackName & "|||" & trackArtist & "|||" & trackTime & "|||" & pState
                end if
            end if
            return "STOPPED"
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            let output = scriptObject.executeAndReturnError(&error)
            
            if let stringValue = output.stringValue {
                if stringValue == "STOPPED" {
                    DispatchQueue.main.async {
                        self.isPlaying = false
                        self.currentLyricLine = "音乐未播放"
                    }
                } else {
                    let parts = stringValue.components(separatedBy: "|||")
                    if parts.count == 4 { // 现在有 4 个部分了
                        let name = parts[0]
                        let artist = parts[1]
                        let time = Double(parts[2]) ?? 0.0
                        let stateStr = parts[3]
                        
                        // 更新播放状态
                        DispatchQueue.main.async {
                            self.isPlaying = (stateStr == "playing")
                        }
                        
                        // 如果暂停了，直接显示暂停提示，不去滚动歌词
                        if stateStr == "paused" {
                            DispatchQueue.main.async {
                                self.currentLyricLine = "已暂停"
                            }
                            return
                        }
                        
                        // 继续判断是否切歌并刷新歌词
                        if name != self.currentTrackName || artist != self.currentArtistName {
                            self.currentTrackName = name
                            self.currentArtistName = artist
                            self.reFetchLyrics()
                        } else {
                            self.updateLyric(for: time)
                        }
                    }
                }
            }
        }
    }
    
    private func updateLyric(for time: Double) {
        guard !currentLyrics.isEmpty else { return }
        
        if let matchedLine = currentLyrics.reversed().first(where: { $0.time <= time }) {
            DispatchQueue.main.async {
                if self.currentLyricLine != matchedLine.text {
                    self.currentLyricLine = matchedLine.text
                }
            }
        }
    }
    
    func togglePlayPause() {
        // 1. 乐观更新：立刻在主线程反转 UI 状态，实现零延迟点击反馈
        DispatchQueue.main.async {
            self.isPlaying.toggle()
            if !self.isPlaying {
                self.currentLyricLine = "已暂停"
            }
        }
        
        // 2. 异步执行：把耗时的 AppleScript 通信丢到后台子线程，防止卡死 UI
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "tell application \"Music\" to playpause"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
    
    func previousTrack() {
        // 切歌时立刻给一个视觉反馈
        DispatchQueue.main.async {
            self.currentLyricLine = "切换中..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "tell application \"Music\" to previous track"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
    
    func nextTrack() {
        DispatchQueue.main.async {
            self.currentLyricLine = "切换中..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "tell application \"Music\" to next track"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
}
