# 顺鼠 Ex-Mouse 1.11

顺鼠是一个尽量简单的 macOS 菜单栏小工具：

- 鼠标滚轮与触控板自然滚动始终相反
- 按住中键左/右滑切换桌面
- 按住中键纵向滑动打开调度中心
- 鼠标侧键切换上一个 / 下一个桌面

菜单里的 `设置` 现在支持分别开关：

- 独立滚动方向
- 手势功能总开关
- 中键滑动手势
- 侧键切换桌面

## 安装

```bash
git clone https://github.com/LUANZHENZHANG/macmouseplus.git
cd macmouseplus
./scripts/build_app.sh
./scripts/install_app.sh
open /Applications/顺鼠.app || open ~/Applications/顺鼠.app
```

打包产物位于：

- `dist/顺鼠.app`

安装路径为：

- 优先：`/Applications/顺鼠.app`
- 无系统写权限时回退到：`~/Applications/顺鼠.app`

建议长期只运行固定安装路径里的 app，不要直接长期运行 `dist` 里的副本。

## 首次授权

首次启动后，按菜单提示授予这些权限：

- 辅助功能
- 输入监控
- 自动化

如果菜单里显示：

- `辅助功能权限：未开启`
- `滚动监听：创建失败`
- `手势监听：创建失败`

就在菜单里依次打开对应系统设置页，把 `顺鼠.app` 勾上，然后完全退出 app 再重新打开一次。

## 开机启动

```bash
cd macmouseplus
./scripts/install_launchagent.sh
```

移除开机启动：

```bash
./scripts/uninstall_launchagent.sh
```

手动退出 app 后，不会被立刻重新拉起；下次登录时会自动启动。

## 卸载

```bash
cd macmouseplus
./scripts/uninstall_launchagent.sh
./scripts/uninstall_app.sh
```

## 维护

更新本机安装版时，重复执行：

```bash
cd macmouseplus
./scripts/build_app.sh
./scripts/install_app.sh
./scripts/install_launchagent.sh
```
