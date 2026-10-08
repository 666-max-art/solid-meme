# 基于仓颉语言的校园学习任务助手

**学伴 StudyMate** 是一个面向大学生日常学习的 Windows 桌面小工具。用仓颉语言记录任务、安排当天的学习时间，并在下次打开时继续使用保存的数据。

这个项目是完成仓颉课程后的一次入门实践。它把类、集合、排序、文件读写和图形界面串成一个可以使用的小作品，适合从基础代码开始阅读和修改。

## 可以做什么

- 添加任务：填写名称、科目、预计用时、优先级和可选截止日期。
- 管理任务：查看、筛选、标记完成、恢复未完成、确认后删除。
- 安排学习：输入当天日期和可用分钟数，生成学习清单。
- 保存数据：任务写入本地 TSV 文件；保存时保留上一份备份。
- 导出计划：把学习清单保存为 Markdown 文件。
- 使用中文输入：Windows 桌面版使用系统输入法；包含对 SDL 窗口输入法上下文的兼容处理。

计划采用简单规则：先考虑逾期任务，再按优先级、截止日期和任务编号排序，依次选取能完整放入剩余时间的任务。它不拆分任务，也不保证得到数学意义上的最优安排。

## 运行环境与构建

当前目标平台为 **Windows x86_64**，使用 **Cangjie SDK 1.2.0** 验证。界面复用 CangjieGUI，底层通过 CangjieSDL 调用 SDL3。

这是源码仓库，运行前需要安装 SDK，并准备 SDL3、SDL3_ttf、SDL3_image 的 Windows 原生开发和运行库。详细步骤见 [构建与运行](docs/BUILD.md)。

在项目根目录打开 PowerShell：

```powershell
# CANGJIE_HOME 已指向 SDK 时可以省略 -SdkHome。
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -SdkHome "你的仓颉 SDK 路径"

# 查看内置示例任务及 60 分钟学习计划。
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run.ps1 -Demo -Plan -SkipBuild

# 打开自己的任务列表。
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run.ps1 -SkipBuild
```

示例数据和个人数据分别保存在 `data/demo-tasks.tsv` 与 `data/tasks.tsv`。两个文件都在运行时生成，不纳入版本控制。已存在的示例文件会继续保留自己的修改；如需恢复初始示例，可先备份并移走该文件。

## 一个示例

内置示例包含仓颉练习、高数练习、集训笔记、英语复习，以及一项已完成任务。日期设为 `2026-10-07`，可用时间为 `60` 分钟时，计划会选择：

| 任务 | 用时 | 选择原因 |
| --- | ---: | --- |
| 整理集训笔记 | 20 分钟 | 已逾期，优先安排 |
| 仓颉类与对象练习 | 30 分钟 | 高优先级，剩余时间足够 |

合计 50 分钟，剩余 10 分钟。这个例子也说明了规则的边界：任务按完整时长安排，不能自动把 40 分钟的高数练习拆成 10 分钟。

## 从哪里读代码

| 文件 | 作用 |
| --- | --- |
| [src/model.cj](src/model.cj) | 任务对象、集合与输入检查 |
| [src/storage.cj](src/storage.cj) | 本地 TSV 保存、读取和备份 |
| [src/planner.cj](src/planner.cj) | 任务排序、时间安排与计划导出 |
| [src/desktop.cj](src/desktop.cj) | 界面、状态和按钮动作 |
| [src/windows_ime.cj](src/windows_ime.cj) | Windows 输入法兼容处理 |
| [src/studymate_test.cj](src/studymate_test.cj) | 核心逻辑的自动测试 |

建议先读前三个文件，再看界面如何调用它们。Windows 输入法处理涉及原生接口，可以留到后面学习。

## 验证

核心测试不依赖图形界面。准备 SDK 后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1 -SdkHome "你的仓颉 SDK 路径"
```

这组测试覆盖输入校验、日期、任务排序、时间预算、TSV 转义和保存读取。桌面启动及中文输入属于另外的人工验证项目，自动测试通过不代表所有电脑上的界面兼容性都已验证。

## 当前边界与下一步

当前主要用于个人本地学习管理。暂未实现任务内容编辑、提醒通知、云端同步或移动端适配。数据按本地文件保存，使用时请自行备份重要内容。

适合继续练习的小改动是“编辑任务”：先理解添加任务和保存流程，再加入修改标题、科目或时长的功能，并补充有意义的测试。

## 开发说明与许可证

这个项目在课程学习的基础上，参考官方资料并使用 AI 辅助完成。AI 参与了代码整理、界面实现和排错。后续目标是读懂核心逻辑，通过自己修改和测试加深理解。

应用代码采用 [MIT License](LICENSE)。`vendor/` 中的上游代码保留各自许可证及 Unicode 声明，来源和快照信息见 [THIRD_PARTY.md](THIRD_PARTY.md)。SDK 和 SDL 原生二进制不随本源码仓库分发。
