//
//  LyricsManager.swift
//  Lyrics-in-MacOSBar
//
//  Created by 何旺霖 on 2026/4/2.
//

import Foundation

enum LyricSourceConfig: String, CaseIterable {
    case auto = "自动匹配 (推荐)"
    case local = "本地歌词文件"
    case netease = "网易云音乐"
    case qq = "QQ 音乐"
    case lrclib = "LRCLIB"
}
// DTO 结构保持不变...
struct NeteaseSearchResponse: Codable { let result: NeteaseSearchResult? }
struct NeteaseSearchResult: Codable { let songs: [NeteaseSong]? }
struct NeteaseSong: Codable { let id: Int }
struct NeteaseLyricResponse: Codable { let lrc: NeteaseLrc? }
struct NeteaseLrc: Codable { let lyric: String? }
struct LRCLibResponse: Codable { let syncedLyrics: String? }
//  QQMusic
struct QQSearchResponse: Codable { let data: QQSearchData? }
struct QQSearchData: Codable { let song: QQSongList? }
struct QQSongList: Codable { let list: [QQSong]? }
struct QQSong: Codable { let songmid: String }
struct QQLyricResponse: Codable { let lyric: String? } // QQ音乐返回的歌词是 Base64 格式

struct ParsedLyricLine {
    let time: TimeInterval
    let text: String
}

class LyricManager {
    
    // 定义本地歌词文件夹路径：用户文档目录/MacLyrics
    var localFolderURL: URL {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documents.appendingPathComponent("MacLyrics")
        }
    
    init() {
        // 初始化时确保文件夹存在，就像在 Java 里执行 mkdirs()
        createFolderIfNeed()
    }
    
    private func createFolderIfNeed() {
        if !FileManager.default.fileExists(atPath: localFolderURL.path) {
            try? FileManager.default.createDirectory(at: localFolderURL, withIntermediateDirectories: true)
            print("📁 已在文档目录创建 MacLyrics 文件夹")
        }
    }
    
    // === 主入口：加入本地优先策略 ===
    func fetchLyrics(trackName: String, artistName: String, sourceConfig: LyricSourceConfig, onStatusUpdate: @escaping (String) -> Void) async -> [ParsedLyricLine] {
            let cleanTrack = cleanText(trackName)
            let cleanArtist = cleanText(artistName)
            
            // 1. 本地优先策略 (选了自动或本地都会走这里)
            if sourceConfig == .auto || sourceConfig == .local {
                onStatusUpdate(sourceConfig == .auto ? "正在匹配本地..." : "正在读取本地歌词...")
                let localResult = fetchFromLocal(track: cleanTrack, artist: cleanArtist)
                if !localResult.isEmpty { return localResult }
                
                // 如果用户强制选了本地，但没找到，直接结束，不往下找
                if sourceConfig == .local { return [] }
            }
            
            // 2. 网易云策略
            if sourceConfig == .auto || sourceConfig == .netease {
                onStatusUpdate("正在搜索网易云...")
                let neteaseResult = await fetchFromNetease(track: cleanTrack, artist: cleanArtist)
                if !neteaseResult.isEmpty { return neteaseResult }
                
                if sourceConfig == .netease { return [] }
            }
            
            // 3. QQ音乐策略
            if sourceConfig == .auto || sourceConfig == .qq {
                onStatusUpdate("正在搜索 QQ 音乐...")
                let qqResult = await fetchFromQQMusic(track: cleanTrack, artist: cleanArtist)
                if !qqResult.isEmpty { return qqResult }
                
                if sourceConfig == .qq { return [] }
            }
            
            // 4. LRCLIB 兜底策略
            if sourceConfig == .auto || sourceConfig == .lrclib {
                onStatusUpdate("正在搜索 LRCLIB...")
                let lrclibResult = await fetchFromLRCLib(track: cleanTrack, artist: cleanArtist)
                if !lrclibResult.isEmpty { return lrclibResult }
                
                if sourceConfig == .lrclib { return [] }
            }
            
            return []
        }
    // === 新增：本地读取逻辑 ===
    private func fetchFromLocal(track: String, artist: String) -> [ParsedLyricLine] {
        // 尝试两种命名匹配： "歌名 - 歌手.lrc" 或 "歌名.lrc"
        let possibleNames = ["\(track) - \(artist).lrc", "\(track).lrc"]
        
        for fileName in possibleNames {
            let fileURL = localFolderURL.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    // 读取文件内容，类似于 Java 的 Files.readAllLines
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    return parseLRC(content)
                } catch {
                    print("本地文件读取失败: \(error)")
                }
            }
        }
        return []
    }
    
    // 后续的 fetchFromNetease, fetchFromLRCLib, cleanText, parseLRC 保持之前的代码即可...
    // (为了篇幅，这里略去重复的解析代码，请确保你在本地代码中保留它们)
    // === 3. 具体数据源请求实现 ===
    
    // 专用方法：请求网易云
    private func fetchFromNetease(track: String, artist: String) async -> [ParsedLyricLine] {
        let keyword = "\(track) \(artist)"
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchUrl = URL(string: "https://music.163.com/api/search/get/web?s=\(encodedKeyword)&type=1&limit=1") else {
            return []
        }
        
        do {
            let (searchData, _) = try await URLSession.shared.data(from: searchUrl)
            let searchResponse = try JSONDecoder().decode(NeteaseSearchResponse.self, from: searchData)
            
            guard let songId = searchResponse.result?.songs?.first?.id else { return [] }
            
            guard let lyricUrl = URL(string: "https://music.163.com/api/song/lyric?id=\(songId)&lv=1") else { return [] }
            let (lyricData, _) = try await URLSession.shared.data(from: lyricUrl)
            let lyricResponse = try JSONDecoder().decode(NeteaseLyricResponse.self, from: lyricData)
            
            if let lrcString = lyricResponse.lrc?.lyric {
                return parseLRC(lrcString)
            }
        } catch {
            print("网易云请求异常: \(error)")
        }
        return []
    }
    
    // 专用方法：请求 QQ 音乐
        private func fetchFromQQMusic(track: String, artist: String) async -> [ParsedLyricLine] {
            let keyword = "\(track) \(artist)"
            guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  // QQ 音乐搜索接口
                  let searchUrl = URL(string: "https://c.y.qq.com/soso/fcgi-bin/client_search_cp?p=1&n=1&w=\(encodedKeyword)&format=json") else {
                return []
            }
            
            do {
                // 第一步：获取歌曲的 songmid
                let (searchData, _) = try await URLSession.shared.data(from: searchUrl)
                let searchResponse = try JSONDecoder().decode(QQSearchResponse.self, from: searchData)
                guard let songmid = searchResponse.data?.song?.list?.first?.songmid else { return [] }
                
                // 第二步：通过 songmid 获取歌词
                guard let lyricUrl = URL(string: "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid=\(songmid)&format=json") else { return [] }
                
                // ⚠️ 核心破解：必须伪造 Referer 请求头，否则 QQ 音乐会拦截请求
                var request = URLRequest(url: lyricUrl)
                request.setValue("https://y.qq.com/", forHTTPHeaderField: "Referer")
                
                let (lyricData, _) = try await URLSession.shared.data(for: request)
                let lyricResponse = try JSONDecoder().decode(QQLyricResponse.self, from: lyricData)
                
                // ⚠️ 核心破解：Base64 解码
                if let base64Lyric = lyricResponse.lyric,
                   let decodedData = Data(base64Encoded: base64Lyric),
                   var lrcString = String(data: decodedData, encoding: .utf8) {
                    
                    // QQ 音乐的歌词里有时会包含 HTML 实体字符，需要简单清洗
                    lrcString = lrcString.replacingOccurrences(of: "&#58;", with: ":")
                    lrcString = lrcString.replacingOccurrences(of: "&#46;", with: ".")
                    lrcString = lrcString.replacingOccurrences(of: "&#10;", with: "\n")
                    
                    return parseLRC(lrcString)
                }
            } catch {
                print("QQ 音乐请求异常: \(error)")
            }
            return []
        }
    
    // 专用方法：请求 LRCLIB
    private func fetchFromLRCLib(track: String, artist: String) async -> [ParsedLyricLine] {
        guard let encodedName = track.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lrclib.net/api/get?track_name=\(encodedName)&artist_name=\(encodedArtist)") else {
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LRCLibResponse.self, from: data)
            
            if let syncedLyrics = response.syncedLyrics {
                return parseLRC(syncedLyrics)
            }
        } catch {
            print("LRCLIB 请求异常: \(error)")
        }
        return []
    }
    
    // === 4. 工具方法 ===
    
    private func cleanText(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "\\s*\\(.*?\\)\\s*", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\s*\\（.*?\\）\\s*", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\s*\\[.*?\\]\\s*", with: "", options: .regularExpression)
        
        if let range = result.range(of: " - ") {
            result = String(result[..<range.lowerBound])
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseLRC(_ lrc: String) -> [ParsedLyricLine] {
        var result: [ParsedLyricLine] = []
        let lines = lrc.components(separatedBy: .newlines)
        
        let pattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2,3})\\](.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return result }
        
        for line in lines {
            let nsString = line as NSString
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let m = nsString.substring(with: match.range(at: 1))
                let s = nsString.substring(with: match.range(at: 2))
                let ms = nsString.substring(with: match.range(at: 3))
                let text = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)
                
                let minutes = Double(m) ?? 0
                let seconds = Double(s) ?? 0
                let milliseconds = Double(ms) ?? 0
                let time = minutes * 60 + seconds + (milliseconds / (ms.count == 2 ? 100 : 1000))
                
                if !text.isEmpty {
                    result.append(ParsedLyricLine(time: time, text: text))
                }
            }
        }
        return result
    }
}
