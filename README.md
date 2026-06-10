# 顺鼠 Ex-Mouse

<p align="center">
  <img src="assets/AppIcon.png" width="128" alt="顺鼠应用图标">
</p>

<p align="center">
  一个轻量的 macOS 菜单栏鼠标增强工具，让鼠标和触控板各自保持顺手的操作方式。
</p>

<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-black">
  <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple%20Silicon-arm64-black">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/License-MIT-green"></a>
</p>

## 作者的话

我不愿意使用太复杂的 Mac 鼠标设置软件，所以让 Codex 设计了这个小工具。

这是一个极其精简、无感的 Mac 鼠标设置工具，重点是不占资源、省空间、单机、不联网！

顺鼠 / Mac Mouse Plus 的主要功能：

- 让 Mac 触控板与鼠标滚轮各自保持顺手的滚动方向。
- 利用鼠标侧键切换不同桌面。
- 利用鼠标手势切换不同桌面（按住中键滑动）。

这个项目从前到后都是 Codex 帮我完成的。我自己用着挺好，估计也有和我一样的朋友需要，所以把它分享出来。

如果使用过程中有任何不合适的地方，请提醒我。谢谢！

## 它能做什么

| 功能 | 操作 |
| --- | --- |
| 独立滚动方向 | 保持触控板自然滚动，只反转鼠标滚轮 |
| 切换桌面 | 按住鼠标中键向左或向右滑动 |
| 打开调度中心 | 按住鼠标中键纵向滑动 |
| 快速切换桌面 | 使用鼠标侧键前进或后退 |

所有功能都可以在菜单栏的顺鼠图标中单独开启或关闭。

> 当前版本：`1.11`。项目仍处于早期阶段，不同品牌鼠标、驱动和 macOS
> 版本可能存在兼容性差异。

## 系统要求

- macOS 13 Ventura 或更高版本
- Apple Silicon（M 系列）Mac
- 带中键或侧键的鼠标，具体按键编号取决于设备和驱动

## 下载与安装

### 下载

**[下载顺鼠 1.11 DMG 安装包](https://github.com/LUANZHENZHANG/macmouseplus/releases/download/v1.11/Shunshu-1.11-macOS-arm64.dmg)**

文件：`Shunshu-1.11-macOS-arm64.dmg`，约 2 MB。

也可以前往 [Releases 页面](https://github.com/LUANZHENZHANG/macmouseplus/releases/latest)
查看最新版和更新说明。

### 安装

1. 双击下载的 `.dmg` 文件。
2. 将“顺鼠.app”拖入窗口中的“Applications”文件夹。
3. 打开 Finder 的“应用程序”目录。
4. 首次启动时，右键点击“顺鼠”，选择“打开”，再确认打开。
5. 按照下方说明授予系统权限。

> 当前安装包使用临时代码签名，尚未经过 Apple Developer ID 签名和公证，因此不能在
> 第一次启动时直接双击打开。请只从本项目 GitHub Releases 下载。

### 更新

下载最新 DMG，退出正在运行的顺鼠，再将新版“顺鼠.app”拖入 Applications 并选择替换。
更新后 macOS 有时会要求重新确认相关权限。

## 首次授权

顺鼠需要以下 macOS 权限才能监听鼠标事件并触发系统操作：

| 权限 | 用途 |
| --- | --- |
| 辅助功能 | 监听和修改滚轮、鼠标中键及侧键事件 |
| 输入监控 | 在其他应用运行时接收全局鼠标事件 |
| 自动化 | 通过 System Events 发送切换桌面的系统快捷键 |

首次启动后，打开：

`系统设置 → 隐私与安全性`

在“辅助功能”“输入监控”和“自动化”中允许 `顺鼠.app`。授权后完全退出并重新启动应用。

顺鼠不连接网络，不包含遥测，不上传鼠标事件，也不记录键盘输入。所有设置仅保存在本机。

## 使用

启动后，顺鼠只显示在 macOS 菜单栏，不会出现在 Dock 中。

菜单中包含：

- **状态**：检查权限、滚动监听和手势监听是否正常。
- **设置**：分别开关独立滚动、中键手势和侧键功能。
- **调试**：显示最近一次事件处理结果，并提供系统权限设置入口。
- **退出**：停止所有监听，并恢复启动前的系统滚动方向设置。

如果菜单显示“监听创建失败”，通常是权限尚未生效。请检查系统设置，完全退出应用后再启动。

## 卸载

1. 从菜单栏的顺鼠图标中选择“退出”。
2. 打开 Finder 的“应用程序”目录。
3. 将“顺鼠.app”移到废纸篓。
4. 如需清除授权记录，可在“系统设置 → 隐私与安全性”中移除顺鼠。

## 已知限制

- 滚轮来源通过事件特征判断，少数高分辨率鼠标可能被误判为触控板。
- 侧键编号由鼠标和驱动决定，部分设备的前进/后退方向可能相反或无法识别。
- 桌面切换依赖 macOS 的 `Control + ←/→` 系统快捷键。
- 当前安装包仅支持 Apple Silicon，使用临时签名且没有 Apple 公证。

遇到问题时，请先查看菜单中的“状态”和“调试”，再按
[Bug 报告模板](https://github.com/LUANZHENZHANG/macmouseplus/issues/new?template=bug_report.yml)
提交系统版本、鼠标型号和复现步骤。

## 参与贡献

欢迎提交问题、兼容性反馈和 Pull Request。开始修改前请阅读
[CONTRIBUTING.md](CONTRIBUTING.md)，安全问题请按照
[SECURITY.md](SECURITY.md) 私下报告。

## 许可证

顺鼠使用 [MIT License](LICENSE) 开源。你可以使用、复制、修改和分发代码，
但需要保留原始版权和许可声明。软件按现状提供，不附带任何担保。
