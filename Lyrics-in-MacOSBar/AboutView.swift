//
//  AboutView.swift
//  Lyrics-in-MacOSBar
//
//  Created by 何旺霖 on 2026/5/15.
//

import SwiftUI
import AppKit

struct AboutView: View {
    //  自动获取当前年份
    private let currentYear = Calendar.current.component(.year, from: Date())
    //  自动读取 Xcode 中的 Version
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    var body: some View {
        VStack(spacing: 20) {
            // 💡 图标区
            Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            
            // 📝 文字介绍区
            VStack(spacing: 6) {
                Text("LyricsOnMacOSBar")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Version \(appVersion)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("一款 macOS 的\nApple Music & Spotify\n极简菜单栏歌词插件")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.8))
                .lineSpacing(4)
            
            // 🔗 开源链接与版权区
            VStack(spacing: 8) {
                Link(destination: URL(string: "https://github.com/motian566/LyricsOnMacOSBar")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("GitHub")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Text("基于 MIT 协议开源")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.top, 10)
            
            // 署名区
            Text("Copyright © \(String(currentYear)) motian566. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 10)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .frame(width: 320)
        // 锁定关于页面的窗口大小，禁止拉伸变形
        .fixedSize()
        // 添加底层材质，完美还原 TenClips 高级感
        .background(Material.ultraThin)
    }
}
