# 🎵 LyricsOnMacOSBar

![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

**LyricsOnMacOSBar** 是一款专为 macOS Apple Music 打造的轻量级菜单栏歌词插件。
采用 Swift & SwiftUI 原生开发，拥有极简的 UI 设计、多重数据源回退机制以及零延迟的播放控制体验。

本项目所有代码及icon均来自**Gemini 3.1 Pro**。

本项目编译于macOS 26.4，Minimum Deployments版本为macOS 15.6，仅测试macOS 26.4上可正常运行，未测试其他版本。

## ✨ 核心特性

- 🏠 **极简与无感**：纯粹的 Agent (UIElement) 应用，没有多余的窗口，不会在 Dock 栏显示图标，安静地常驻在菜单栏。
- 🔄 **多数据源智能轮询**：
  - **本地优先**：最高优先级读取本地 `.lrc` 文件，完美解决 Live 版、特殊版歌曲时间轴不匹配的强迫症痛点。
  - **网络降级**：依次通过 **网易云音乐 -> QQ 音乐 -> LRCLIB** 进行责任链搜索，大幅提高歌词命中率。
- ⚡️ **零延迟原生控制台**：
  - 集成「上一首 / 播放暂停 / 下一首」图形化多媒体控制。
  - 采用 **乐观更新 (Optimistic Update)** 与多线程异步机制，点击瞬间即刻反馈，告别系统 API 的卡顿感。
- 🎨 **高度定制化**：支持随时在菜单栏手动强制切换当前歌曲的歌词抓取源。

## 🚀 快速开始

### 方式一：直接下载运行 (推荐)
1. 进入本仓库的 [Releases](#) 页面。
2. 下载最新版本的 `LyricsOnMacOSBar-1.7.1.dmg`。
3. 解压并将 `.app` 文件拖入 `应用程序 (Applications)` 文件夹，双击运行即可。
*(注：首次运行可能需要在“系统设置 -> 隐私与安全性”中二次确认，如启动台未出现app，请前往访达-应用程序，右键LyricsOnMacOSBar图标，点击打开，晚些时候即可出现。)*

### 方式二：本地编译
1. 克隆本项目：`git clone https://github.com/motian566/LyricsOnMacOSBar.git`
2. 使用 Xcode 打开 `LyricsOnMacOSBar.xcodeproj`。
3. 信任开发者证书，按 `Cmd + R` 即可编译运行。

## 📁 本地歌词使用说明

如果你发现某些歌曲（如演唱会 Live 版）的网源时间轴完全对不上，你可以使用本地歌词功能：
1. 点击菜单栏歌词图标，选择 **「打开本地歌词文件夹」**（默认路径为 `~/Documents/MacLyrics`）。
2. 将准备好的 `.lrc` 歌词文件放入该文件夹中。
3. **命名规范**：`歌名 - 歌手.lrc` 或 `歌名.lrc`（注意去除多余的后缀如 (Live版)）。
4. 切换歌曲，系统将优先精准读取你的本地配置！

## 👨‍💻 开发者

- **motian566** ## ⚖️ 免责声明与开源协议

本项目基于 **MIT License** 开源。

**【开源与免费声明】**
本软件代码完全公开。严禁任何个人或组织将本软件用于商业牟利、二次打包或倒卖行为。

**【免责声明】**
本软件按“原样”提供，仅作个人编程学习与技术交流使用。软件本身不提供、不存储任何音乐资源。作者不对使用本软件抓取网络歌词的数据准确性、潜在的版权纠纷，以及由此引发的任何直接或间接损失承担法律责任。
