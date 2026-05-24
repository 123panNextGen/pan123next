<p align="center">
  <img src="assets/image/app_icon.png" width="128" height="128" alt="Pan123 Next">
</p>

<h1 align="center">Pan123 Next 🚀</h1>

<p align="center">
  <em>你的云盘，随叫随到</em>
  <br>
  <img src="doc/img/ScreenShot-1.png" alt="ScreenShot-1">
</p>

[![Stars](https://img.shields.io/github/stars/123panNextGen/pan123next?style=for-the-badge)](https://github.com/123panNextGen/pan123next/stargazers)
[![Issues](https://img.shields.io/github/issues/123panNextGen/pan123next?style=for-the-badge)](https://github.com/123panNextGen/pan123next/issues)
[![License](https://img.shields.io/badge/license-GPL%203.0-blue?style=for-the-badge)](https://github.com/123panNextGen/pan123next/blob/main/LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Release](https://img.shields.io/github/v/release/123panNextGen/pan123next?style=for-the-badge)](https://github.com/123panNextGen/pan123next/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/123panNextGen/pan123next/total?style=for-the-badge)](https://github.com/123panNextGen/pan123next/releases)

---

一款使用 **Dart/Flutter** 编写的第三方 123云盘 桌面客户端，采用 **Fluent UI** 设计风格，支持多平台运行（Windows / macOS / Linux / Android）。

> ⚠️ 本项目仍在早期开发阶段，功能尚不齐全，可能存在较多问题。

## 📁 目录结构

```
pan123next/
├── lib/
│   ├── main.dart                  # 应用入口
│   ├── app.dart                   # 应用根组件 & 路由
│   ├── common/
│   │   ├── api/                   # API 层
│   │   │   ├── session.dart       # 网络会话 & 请求封装 (Dio)
│   │   │   ├── model.dart         # 数据模型定义
│   │   │   └── device.dart        # 设备信息模拟
│   │   ├── data/                  # 本地持久化层
│   │   │   ├── app.dart           # 应用设置 (SharedPreferences)
│   │   │   ├── user.dart          # 用户数据
│   │   │   └── downloader.dart    # 下载记录
│   │   ├── downloader/            # 下载引擎
│   │   │   ├── model.dart         # 下载模型 & 分片定义
│   │   │   └── session.dart       # 下载会话管理
│   │   ├── app_session.dart       # 全局应用状态 (GetX)
│   │   ├── const.dart             # 常量
│   │   ├── format.dart            # 格式化工具 & 文件图标
│   │   ├── get_platform.dart      # 平台判断
│   │   ├── logger.dart            # 日志工具
│   │   └── version.dart           # 版本信息
│   ├── screens/
│   │   ├── login_screen.dart      # 登录界面
│   │   └── main_screen.dart       # 主界面 (导航框架)
│   ├── pages/
│   │   ├── login/                 # 登录页
│   │   │   ├── view.dart          # 登录表单
│   │   │   └── control.dart       # 登录逻辑
│   │   ├── file_list/             # 文件列表页
│   │   │   ├── view.dart          # 文件浏览器
│   │   │   └── dialog.dart        # 对话框
│   │   ├── transfer/              # 传输管理页
│   │   │   ├── view.dart          # 下载/上传列表
│   │   │   └── dialog.dart        # 添加下载对话框
│   │   └── settings/              # 设置页
│   │       └── view.dart
│   └── widgets/
│       ├── downloader_tile.dart    # 下载任务卡片
│       ├── setting_card.dart       # 设置分组卡片
│       ├── show_info_bar.dart      # 提示栏
│       └── window_buttons.dart     # 窗口按钮
├── assets/
│   ├── image/app_icon.png         # 应用图标
│   ├── data/device.json           # 模拟设备列表
│   └── fonts/                     # JetBrainsMono Nerd Font
├── doc/
│   ├── ChangeLog.md               # 变更日志
│   ├── ReleaseTemplate.md         # 发布模板
│   └── GitCommitMessageStyle.md   # 提交规范
├── script/                        # 发布辅助脚本
├── .github/workflows/             # CI/CD 流水线
├── pubspec.yaml
└── pyproject.toml
```

## ✨ 功能

| 功能 | 状态 |
|------|------|
| 用户名/密码登录 | ✅ |
| 二维码登录 | 🚧 计划中 |
| 文件浏览（面包屑导航） | ✅ |
| 新建文件夹 | ✅ |
| 文件下载（分片并行下载） | ✅ |
| 断点续传 | ✅ |
| 下载进度 & 速度显示 | ✅ |
| 外部 URL 下载 | ✅ |
| 文件上传 | 💡 准备中 |
| 快速编辑 | 💡 准备中 |
| 主题切换（亮色/暗色） | ✅ |
| 强调色自定义 | ✅ |
| 下载路径设置 | ✅ |
| Windows / macOS / Linux | ✅ |
| Android APK | ✅ |

## 📦 使用方法

### 预编译二进制

从 [GitHub Releases](https://github.com/123panNextGen/pan123next/releases) 下载对应平台的安装包即可。

| 平台 | 文件 |
|------|------|
| Windows | `Pan123Next-Windows.zip` |
| macOS | `Pan123Next-macos.zip` |
| Linux | `Pan123Next-Linux.zip` |
| Android | `Pan123Next-Android.apk` |

### 从源码运行

环境要求：

| 名称 | 版本 |
|------|------|
| Flutter SDK | 3.11+ |
| Dart SDK | 3.11+ |

```bash
# 克隆仓库
git clone https://github.com/123panNextGen/pan123next.git
cd pan123next

# 安装依赖
flutter pub get

# 运行
flutter run
```

如需构建发布版本：

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Android APK
flutter build apk --release
```

## ⚙️ 配置与数据

🔒 应用配置与登录凭据会存储在本地，不会上传到服务器

存储的内容包括：

- 登录凭据（用户名、Token、设备标识）
- 主题与强调色设置
- 下载路径配置
- 下载任务记录（含分片进度，支持重启恢复）

## 💬 社区与支持

- [GitHub Issues](https://github.com/123panNextGen/pan123next/issues) — 报告 Bug 或功能建议

## 📜 许可与免责声明

本项目基于 **GPL 3.0** 协议开源。

```
本项目为个人学习与技术研究目的开发，与 123 云盘官方无任何关联。
使用本项目即表示您理解并同意：
- 本软件按"原样"提供，不附带任何明示或暗示的担保
- 开发者不对因使用本软件造成的任何损失承担责任，包括但不限于
  数据丢失、账号封禁、服务中断等
- 您应自行遵守 123 云盘服务条款及适用法律法规
- 禁止将本项目用于任何商业用途
```

## ❤️ 贡献

欢迎提交 Pull Request 或 Issue！

本项目不提倡完全使用 AI 编写代码，使用 AI 工具时请确保您理解其生成的内容。

提交时请遵循 [Git 提交规范](doc/GitCommitMessageStyle.md)。

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=123panNextGen/pan123next&type=Date)](https://star-history.com/#123panNextGen/pan123next&Date)

---

<p align="center">Made with ❤️ by 123panNextGen Team</p>
<p align="center">⚡ Powered with <b>you</b></p>
