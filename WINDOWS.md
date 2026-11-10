# Windows 安装与下载排障

适用：**NCM Converter v0.2.0-rc.1**，Windows x64。

这个版本由 PyInstaller（目录模式）和 Inno Setup 打包，发布的 Windows 程序**没有 Authenticode 代码签名**。预发布（Pre-release）标签只是 GitHub 的版本状态，本身不会让 Windows 拒绝安装。签名缺失及新发布文件缺少信誉可能增加警告概率，但**不能仅凭截图断定是误报**。

## 已验证与尚未验证

GitHub Actions 对 `v0.2.0-rc.1` 的 Windows 构建执行了单元测试、生成安装包、静默安装到中文路径，并运行打包后转换流程，均成功：
[Windows 构建记录](https://github.com/DsirNG/ncm-converter/actions/runs/42180231059)。

这些验证证明 CI 环境能够安装运行，不代表所有用户设备都会通过浏览器、SmartScreen、Defender 或组织策略。普通 Windows 10/11 用户环境和第三方杀毒软件仍需单独测试。

## 下载显示“已删除”或者双击提示“Windows 无法访问指定设备、路径或文件”

1. 打开 Chrome 的 `Ctrl+J`，查看下载条目的完整状态。**“已删除”只说明下载文件已不存在，不足以判定删除者。**
2. 打开 **Windows 安全中心 → 病毒和威胁防护 → 保护历史记录**，对照下载时间寻找拦截、隔离或删除记录。不要关闭防护，也不要在未确认检测原因前恢复可疑文件。
3. 如果浏览器显示“由所属组织管理”，打开 `chrome://policy` 检查下载限制和安全浏览策略。该提示本身不代表一定拦截了此文件。
4. 确认目标 `.exe` 是否仍然存在于下载文件夹。下载目录中的 `.crdownload` 只是未完成或未清理的临时文件，**不能改名为 EXE 运行**。
5. 如果文件仍存在，先检查哈希与签名状态，再根据系统提示继续排查。

### 只读诊断脚本

在 PowerShell 中进入项目根目录运行：

```powershell
.\scripts\diagnose-windows-installer.ps1
```

如果安装包放在别处：

```powershell
.\scripts\diagnose-windows-installer.ps1 -InstallerPath 'D:\Downloads\NCM-Converter-0.2.0-rc.1-Windows-x64-Setup.exe'
```

该脚本只打印下载文件是否存在、大小、SHA-256、Authenticode 签名状态、可读取的下载安全区域标记、Chrome 临时文件及最近 7 天 Microsoft Defender 检测记录；**不修改任何设置，不自动解封或运行文件**。部分安全记录可能要求管理员权限，组织管理设备也可能限制读取。

### 手工校验安装包 SHA-256

GitHub 发布的 v0.2.0-rc.1 Windows 安装包 SHA-256：

```text
2f5ee91f682bc621c368e04f53dc9965809fa9d756d46940670b39d5b43b1cd5
```

文件存在时，用 PowerShell：

```powershell
Get-FileHash "$env:USERPROFILE\Downloads\NCM-Converter-0.2.0-rc.1-Windows-x64-Setup.exe" -Algorithm SHA256
Get-AuthenticodeSignature "$env:USERPROFILE\Downloads\NCM-Converter-0.2.0-rc.1-Windows-x64-Setup.exe"
```

哈希一致可以确认与发布的字节一致，但**不能保证文件安全**。哈希不一致时不运行文件。

## 安装版无法使用时

Release 同时提供 `NCM-Converter-0.2.0-rc.1-Windows-x64-Portable.zip`，可以用于与安装包区分排查。解压后需完整保留 `_internal` 目录。如果安全软件对便携版也报警，先调查报警原因，不要通过排除安全扫描来强行运行。

## 发布质量的后续改进方向

- 为应用主程序和安装包申请并配置正规 Authenticode 签名，结合实际下载量逐步建立信誉；**签名也不能保证绝不误报**。
- 在干净的 Windows 10/11 真实设备上验证浏览器下载、用户交互安装与 Defender/SmartScreen 提示。
- 保留发布 SHA-256 与构建出处，收集拦截时的威胁名称、检测来源和产品版本，再决定是否需要向安全厂商提交误报复核。
