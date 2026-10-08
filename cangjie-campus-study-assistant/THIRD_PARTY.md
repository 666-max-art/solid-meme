# 第三方依赖与源码快照

本仓库包含构建所需的 CangjieGUI 与 CangjieSDL 源码副本，保留上游许可证和 Unicode 声明。应用使用 Cangjie SDK 1.2.0 验证；两个依赖的 manifest 标注 SDK 1.0.5。

| 依赖 | manifest 版本 | 上游来源 | 保留的许可证 |
| --- | --- | --- | --- |
| CangjieGUI / cui | 0.9.6 | https://github.com/SunriseSummer/CangjieGUI | vendor/CangjieGUI/LICENSE |
| CangjieSDL / sdl | 0.9.6 | https://github.com/SunriseSummer/CangjieSDL | vendor/CangjieSDL/LICENSE |
| Unicode 数据 | 以声明原文为准 | 上游的 .dev/unicode/LICENSE.txt | 两个依赖的 licenses/UNICODE.txt |

## 快照记录

原始 GitHub ZIP 的全局注释包含以下 commit 元数据。准备本作品时，逐文件 SHA-256 比较确认 635 个仓颉源码文件与原始 ZIP 中的对应源码一致。

| 项目 | commit | 仓颉源码文件数 |
| --- | --- | ---: |
| CangjieGUI | 3a4cc3431816d1f89d50ee2f00245c90e2fc0554 | 405 |
| CangjieSDL | 896b175a6a8b012a477058042c089deddc348921 | 230 |

原始 ZIP 的 SHA-256：

```text
CangjieGUI-main.zip AB4264F8912E67D687DF9D5FB0C4A423C64BCCD21390DFBA57CC7ACF356CD61C
CangjieSDL-main.zip 99FFFEB2AC09075F012FB81566C2CD574E69DE160B304D15777B6C32530009DC
```

CangjieGUI 的 manifest 将 sdl 改成本地路径依赖：`sdl = { path = "../CangjieSDL" }`。这份精简副本仅包含 src、manifest、README 和许可证，未包含上游完整文档、示例与开发脚本；上游 README 中的部分相对链接需要到来源仓库中查看。

## 原生库

本机验证使用的 DLL 文件版本为：

| 库 | 文件版本 | 官方来源 |
| --- | --- | --- |
| SDL3 | 3.4.12.0 | https://github.com/libsdl-org/SDL/releases/tag/release-3.4.12 |
| SDL3_ttf | 3.2.2.0 | https://github.com/libsdl-org/SDL_ttf/releases/tag/release-3.2.2 |
| SDL3_image | 3.4.6.0 | https://github.com/libsdl-org/SDL_image/releases/tag/release-3.4.6 |

SDK 与 SDL 原生二进制均不包含在这个源码仓库中。请从官方来源准备开发与运行库，并保留下载件自带的许可证和第三方声明。若后续单独发布 Windows 运行包，还需包含原生库、SDK 运行时和所用字体或编解码组件的适用声明；应用的 MIT 许可证不覆盖这些依赖。
