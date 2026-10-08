# Windows 构建与运行

## 1. SDK

安装 [仓颉官方网站](https://cangjie-lang.cn/) 提供的 Windows x86_64 SDK。本作品实际验证使用 SDK **1.2.0**。

以下脚本按顺序寻找 SDK：`-SdkHome` 参数、`CANGJIE_HOME` 环境变量、PATH 中的 `cjc.exe`。不会写入系统环境变量。

## 2. SDL 原生库

CangjieSDL 是仓颉绑定，仍需要原生 SDL 库。下载 Windows x64 版本并解压：

- [SDL 3.4.12](https://github.com/libsdl-org/SDL/releases/tag/release-3.4.12)
- [SDL_ttf 3.2.2](https://github.com/libsdl-org/SDL_ttf/releases/tag/release-3.2.2)
- [SDL_image 3.4.6](https://github.com/libsdl-org/SDL_image/releases/tag/release-3.4.6)

保留下载件中的许可证和声明。将下面三个运行库复制到 `vendor/CangjieSDL/.sdl3/`：

```text
SDL3.dll
SDL3_ttf.dll
SDL3_image.dll
```

本仓库使用的 Windows CJNative 链接方式还需要同目录存在 `lib` 前缀的名称。若发行件没有这些文件名，可以在本机复制一份：

```powershell
$native = ".\vendor\CangjieSDL\.sdl3"
Copy-Item "$native\SDL3.dll" "$native\libSDL3.dll"
Copy-Item "$native\SDL3_ttf.dll" "$native\libSDL3_ttf.dll"
Copy-Item "$native\SDL3_image.dll" "$native\libSDL3_image.dll"
```

这只是给同一份 DLL 增加链接所需的文件名，不会改变库内容。不需要复制到 Windows 系统目录。本次验证使用上述六个 DLL；不同发行件若包含额外依赖，请同时保留其配套文件。

`.sdl3/` 与编译产物被 Git 忽略，不会随源码提交。

## 3. 构建

在包含 `cjpm.toml` 的项目根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -SdkHome "你的仓颉 SDK 路径"
```

脚本先配置当前进程的 SDK 环境，再执行 `cjpm build`，从仓库中的源码编译 CangjieGUI、CangjieSDL 和应用。

SDK 1.2.0 的默认可执行文件为 `target/release/bin/main.exe`。脚本复制为 `StudyMate.exe`，并在同目录放入三个 SDL DLL 与两个 SDK 运行时 DLL。该路径为本机生成目录，仓库不分发预编译程序。

## 4. 启动

```powershell
# 内置示例 + 学习规划页
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run.ps1 -Demo -Plan -SkipBuild

# 个人任务
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run.ps1 -SkipBuild
```

省略 `-SkipBuild` 会先构建；这时同样可以传 `-SdkHome`。两个入口使用不同数据文件，示例不会覆盖个人任务。直接双击生成的 `StudyMate.exe` 默认进入内置示例。

## 5. 核心测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1 -SdkHome "你的仓颉 SDK 路径"
```

测试脚本只编译任务模型、存储、规划和对应测试，不启动桌面窗口，也不需要 SDL 库。SDK 环境设置只作用于当前 PowerShell 进程。

## CodeArts IDE for Cangjie

在 IDE 中选择“打开文件夹”，打开项目根目录。在终端执行上述构建、测试与启动命令。仓库不包含某台电脑的 SDK 绝对路径、个人 IDE 配置或调试产物。

## 常见问题

- **缺少 SDL 库**：检查 `.sdl3` 中六个文件名及 x64 平台是否正确。
- **找不到 SDK**：传入安装目录，而不是 `bin` 目录；其中应包含 `bin/cjc.exe` 和 `envsetup.ps1`。
- **打开时提示数据损坏**：关闭程序，先备份原文件，再检查同目录的 `.bak` 文件。
- **计划没有填满预算**：这是当前完整任务排序规则的结果，可以手动把较长任务拆成小任务。
