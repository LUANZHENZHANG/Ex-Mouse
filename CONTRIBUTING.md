# 参与贡献

感谢你帮助改进顺鼠。这个项目直接处理全局输入事件，因此行为正确、资源占用和可恢复性
比功能数量更重要。

## 提交问题

提交 Bug 前请先搜索已有 Issue，并准备以下信息：

- macOS 版本和 Mac 芯片类型
- 鼠标品牌、型号及是否安装厂商驱动
- 顺鼠版本或 Git commit
- 已授予的系统权限
- 菜单“状态”和“调试”中显示的信息
- 最小、稳定的复现步骤

请勿在公开 Issue 中提交密码、密钥、个人文件或其他敏感信息。

## 开发环境

要求：

- macOS 13 或更高版本
- Swift 6.3
- Xcode Command Line Tools

```bash
git clone https://github.com/LUANZHENZHANG/Ex-Mouse.git
cd Ex-Mouse
swift build
./scripts/build_app.sh
./scripts/build_dmg.sh
```

生成的应用位于 `dist/顺鼠.app`。构建目录和应用产物不应提交到 Git。

## 修改原则

- 保持菜单栏工具轻量，不引入不必要的常驻依赖。
- 权限用途必须明确，新增权限时同步更新 README。
- 不收集、保存或上传用户输入事件。
- 修改事件监听时，应保证应用退出后停止监听并恢复修改过的系统状态。
- 优先修复兼容性和稳定性问题，再考虑扩大功能范围。
- 代码和注释保持简洁；用户界面文本使用清晰的中文。

## 验证

项目当前没有自动化测试套件。提交 Pull Request 前至少运行：

```bash
swift build
./scripts/build_app.sh
```

涉及滚动或手势行为时，还需要手动检查：

1. 鼠标滚轮方向与触控板方向符合预期。
2. 中键点击、拖动和侧键不会产生重复事件。
3. 权限缺失时应用不会崩溃，并能显示可理解的状态。
4. 关闭功能或退出应用后，监听和系统滚动设置被正确恢复。
5. Finder、浏览器和至少一个原生 App 中的滚动行为一致。

## Pull Request

- 一个 PR 只解决一个明确问题。
- 说明问题、实现方式、验证步骤和可能的兼容性影响。
- 不要提交 `.build`、`.build-cache`、`dist` 或 `.DS_Store`。
- 用户可见行为发生变化时，同步更新 README 和 `CHANGELOG.md`。
- 保持提交历史清晰，不要混入无关格式化或重构。

提交贡献即表示你同意按照项目的 [MIT License](LICENSE) 授权该贡献。
