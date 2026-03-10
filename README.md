# PowerShell Clash Verge Proxy Profile

此目录为一个 PowerShell 配置文件脚本 `Microsoft.PowerShell_profile.ps1`，用于自动管理 Clash Verge 代理设置。

## 功能
- 自动检测系统代理并配置终端环境变量（HTTP_PROXY, HTTPS_PROXY 等）。
- 通过 Clash API 获取版本和模式信息。
- 提供便捷命令切换代理状态。

## 配置
脚本使用默认值：
- 代理: `127.0.0.1:7897`（端口：`自行复核`）
- API: `127.0.0.1:9097` (密钥: `自行配置`)

如有不同，请修改脚本中的变量。

## 使用
1. 将脚本放入 PowerShell 配置文件目录（`$PROFILE`）。
2. 打开clash外部控制。
3. 重启 PowerShell，脚本自动运行。
4. 命令：
   - `proxy` - 启用终端代理。
   - `unproxy` - 禁用终端代理。
   - `proxy-status` - 查看当前代理变量。

## 许可
个人使用，随意修改。