package studymate

import cui.*
import std.fs.*
import sdl.system.{SdlHint, SdlHintSetting, ApplicationPaths}

// 桌面界面复用命令行版的任务、存储与规划模块。
class DesktopModel {
    let book: State<TaskBook>
    let path: String
    let demo: Bool
    let page = State<Int64>(0)
    let message = State<String>("修改后自动保存到本地")
    let title = State<String>("")
    let subject = State<String>("仓颉")
    let minutes = State<String>("30")
    let priority = State<Int64>(0)
    let due = State<String>("")
    let filter = State<Int64>(0)
    let search = State<String>("")
    let deleteId = State<Int64>(0)
    let date = State<String>("2026-10-07")
    let budget = State<String>("60")
    let plan = State<StudyPlan>(StudyPlan())
    let planReady = State<Bool>(false)
    let planDate = State<String>("")
    let planBudget = State<Int64>(0)

    init(path: String, demo: Bool) {
        this.path = path
        this.demo = demo
        var initial = loadBook(path)
        if (demo && !exists(path)) {
            initial.add("仓颉类与对象练习", "仓颉", 30, 1, "2026-10-08")
            initial.add("高数极限练习", "高数", 40, 1, "2026-10-09")
            initial.add("整理集训笔记", "仓颉", 20, 2, "2026-10-06")
            initial.add("英语单词复习", "英语", 15, 3, "")
            initial.add("跑通 Hello World", "仓颉", 10, 2, "")
            initial.setDone(5, true)
            saveBook(path, initial)
        }
        this.book = State<TaskBook>(initial)
    }

    func commit(next: TaskBook, notice: String): Unit {
        // 保存成功以后才更新屏幕；失败时保留原来的任务本。
        saveBook(path, next)
        book.value = next
        planReady.value = false
        deleteId.value = 0
        message.value = notice
    }

    func addTask(): Unit {
        try {
            let next = book.value.copyBook()
            next.add(title.value, subject.value, readNumber(minutes.value.trimAscii()),
                priority.value + 1, due.value.trimAscii())
            commit(next, "任务已添加，数据已保存")
            title.value = ""
            due.value = ""
        } catch (e: Exception) { message.value = "添加失败：${e.message}" }
    }

    func toggle(task: StudyTask): Unit {
        try {
            let next = book.value.copyBook()
            next.setDone(task.id, !task.done)
            commit(next, if (task.done) {"已恢复为待完成，数据已保存"} else {"已标记完成，数据已保存"})
        } catch (e: Exception) { message.value = "保存失败：${e.message}" }
    }

    func remove(id: Int64): Unit {
        if (deleteId.value != id) {
            deleteId.value = id
            message.value = "确认后才能删除；点“取消”可保留任务"
            return
        }
        try {
            let next = book.value.copyBook()
            next.delete(id)
            commit(next, "任务已删除，数据已保存")
        } catch (e: Exception) { message.value = "删除失败：${e.message}" }
    }

    func generate(): Unit {
        try {
            let day = date.value.trimAscii()
            let amount = readNumber(budget.value.trimAscii())
            let result = makePlan(book.value, day, amount)
            plan.value = result
            planDate.value = day
            planBudget.value = amount
            planReady.value = true
            message.value = "学习建议已生成；任务不会自动标记完成"
        } catch (e: Exception) {
            planReady.value = false
            message.value = "规划失败：${e.message}"
        }
    }

    func exportReport(): Unit {
        if (!planReady.value) { message.value = "请先生成学习建议"; return }
        try {
            let reportPath = Path(path).parent.toString() + "/learning-report.md"
            File.writeTo(reportPath, makeReport(book.value, planDate.value, planBudget.value).toArray())
            message.value = "报告已保存：${reportPath}"
        } catch (e: Exception) { message.value = "导出失败：${e.message}" }
    }
}

func studyTheme(): Theme {
    Theme(bg: Color.rgb(246, 247, 250), panel: Color.rgb(255, 255, 255),
        panelEdge: Color.rgb(223, 225, 232), text: Color.rgb(34, 37, 45),
        mutedText: Color.rgb(106, 112, 127), accent: Color.rgb(196, 53, 39),
        accentText: Color.rgb(255, 255, 255), accentSoft: Color.rgb(252, 238, 235),
        field: Color.rgb(249, 250, 252), fieldActive: Color.rgb(255, 244, 241),
        danger: Color.rgb(181, 39, 39), radius: 13.0, controlRadius: 8.0)
}

func heading(value: String): Unit { Label(value).fontSize(20.fp) }
func caption(value: String): Unit { Label(value).muted().fontSize(13.fp).maxLines(3) }

func metric(title: String, value: String, detail: String): Unit {
    Panel {
        VStack {
            caption(title)
            Label(value).fontSize(25.fp).foregroundColor(Color.rgb(196, 53, 39))
            caption(detail)
        }.spacing(5.vp).hug()
    }.contentPadding(15.vp)
}

func appView(m: DesktopModel): Unit {
    VStack {
        HStack {
            VStack {
                Label("学伴 StudyMate").fontSize(27.fp)
                caption("从一项任务开始，把课后时间安排好")
            }.spacing(3.vp).hug()
            Spacer()
            Label(if (m.demo) {"演示数据 · 仓颉桌面版"} else {"我的任务 · 仓颉桌面版"})
                .foregroundColor(Color.rgb(196, 53, 39)).fontSize(14.fp)
        }.crossAxisAlignment(CrossAxisAlignment.Center).hug()
        HStack {
            Panel {
                VStack {
                    caption("学习工作区")
                    Button("任务清单", {=> m.page.value = 0})
                        .role(if (m.page.value == 0) {ButtonRole.Primary} else {ButtonRole.Normal}).fillWidth()
                    Button("时间规划", {=> m.page.value = 1})
                        .role(if (m.page.value == 1) {ButtonRole.Primary} else {ButtonRole.Normal}).fillWidth()
                    Spacer()
                    caption("本地保存\n不用登录，退出后可继续")
                    caption("预计分钟由自己填写，\n建议可以根据实际情况调整")
                }.spacing(13.vp)
            }.contentPadding(16.vp).hug().width(172.vp)
            VStack {
                if (m.page.value == 0) { tasksPage(m) } else { planPage(m) }
            }.spacing(14.vp).flex()
        }.spacing(16.vp).flex()
        Label(m.message.value).fontSize(13.fp).foregroundColor(Color.rgb(100, 106, 121)).maxLines(2)
    }.spacing(15.vp).padding(20.vp)
}

func tasksPage(m: DesktopModel): Unit {
    var done: Int64 = 0
    var pending: Int64 = 0
    for (t in m.book.value.tasks) { if (t.done) {done++} else {pending += t.minutes} }
    let completedCount = done
    let pendingMinutes = pending
    Grid(3) {
        metric("全部任务", "${m.book.value.tasks.size} 项", "学习安排集中记录")
        metric("已经完成", "${completedCount} 项", "完成一项，就记录一项")
        metric("待完成预计用时", "${pendingMinutes} 分钟", "预计用时，不是计时记录")
    }.spacing(12.vp).height(112.vp)
    HStack {
        Panel {
            VStack {
                HStack {
                    heading("任务清单")
                    Spacer()
                    Dropdown(["全部状态", "待完成", "已完成"], m.filter, key: "filter").width(132.vp)
                }.hug()
                TextField(m.search, key: "search").placeholder("按科目筛选，留空查看全部").fillWidth()
                ScrollView {
                    VStack {
                        var shown: Int64 = 0
                        for (t in m.book.value.tasks) {
                            let statusMatches = m.filter.value == 0 || (m.filter.value == 1 && !t.done) ||
                                (m.filter.value == 2 && t.done)
                            if (statusMatches && (m.search.value.trimAscii().isEmpty() || t.subject == m.search.value.trimAscii())) {
                                shown++
                                Keyed("task${t.id}") { taskRow(m, t) }
                            }
                        }
                        if (shown == 0) { caption("没有匹配的任务，可以先添加一项。") }
                    }.spacing(10.vp).hug()
                }.flex()
            }.spacing(12.vp)
        }.contentPadding(16.vp).flex()
        Panel {
            ScrollView {
                VStack {
                    heading("添加学习任务")
                    caption("任务名称")
                    TextField(m.title, key: "title").placeholder("例如：复习仓颉函数").fillWidth()
                    caption("科目")
                    TextField(m.subject, key: "subject").fillWidth()
                    HStack {
                        VStack {
                            caption("预计分钟")
                            TextField(m.minutes, key: "minutes").width(112.vp)
                        }.spacing(5.vp).hug()
                        VStack {
                            caption("优先级")
                            Dropdown(["高", "中", "低"], m.priority, key: "priority").width(112.vp)
                        }.spacing(5.vp).hug()
                    }.spacing(12.vp).hug()
                    caption("截止日期（可留空）")
                    TextField(m.due, key: "due").placeholder("YYYY-MM-DD").fillWidth()
                    Button("添加并保存", {=> m.addTask()}).role(ButtonRole.Primary).fillWidth()
                    caption("用一个清楚的小任务，代替一个模糊的大目标。")
                }.spacing(10.vp).hug()
            }
        }.contentPadding(17.vp).hug().width(278.vp)
    }.spacing(14.vp).flex()
}

func taskRow(m: DesktopModel, t: StudyTask): Unit {
    Panel {
        VStack {
            Label(t.title).fontSize(16.fp).maxLines(2)
            caption("${t.subject} · ${t.minutes} 分钟 · ${priorityName(t.priority)}优先级 · " +
                if (t.due.isEmpty()) {"无截止日期"} else {"截止 ${t.due}"})
            HStack {
                Label(if (t.done) {"已完成"} else {"待完成"}).fontSize(13.fp)
                    .foregroundColor(if (t.done) {Color.rgb(29, 130, 102)} else {Color.rgb(196, 53, 39)})
                Spacer()
                Button(if (t.done) {"撤回完成"} else {"标记完成"}, {=> m.toggle(t)}).width(100.vp)
                Button(if (m.deleteId.value == t.id) {"确认删除"} else {"删除"}, {=> m.remove(t.id)}).width(90.vp)
                if (m.deleteId.value == t.id) { Button("取消", {=> m.deleteId.value = 0}).width(60.vp) }
            }.crossAxisAlignment(CrossAxisAlignment.Center).hug()
        }.spacing(5.vp).hug()
    }.contentPadding(12.vp).hug()
}

func planPage(m: DesktopModel): Unit {
    Panel {
        VStack {
            heading("今天，先做哪些任务？")
            HStack {
                VStack { caption("规划日期"); TextField(m.date, key: "date").width(180.vp) }.spacing(5.vp).hug()
                VStack { caption("可用时间 / 分钟"); TextField(m.budget, key: "budget").width(150.vp) }.spacing(5.vp).hug()
                Button("生成学习建议", {=> m.generate()}).role(ButtonRole.Primary).width(165.vp)
                Button("导出报告", {=> m.exportReport()}).width(120.vp)
            }.spacing(16.vp).crossAxisAlignment(CrossAxisAlignment.End).hug()
            caption("逾期优先 → 优先级 → 截止日期 → 编号；依次选择能放入预算的任务")
        }.spacing(12.vp).hug()
    }.contentPadding(20.vp).hug()
    if (m.planReady.value) {
        let p = m.plan.value
        Grid(3) {
            metric("今天可用", "${m.planBudget.value} 分钟", m.planDate.value)
            metric("建议安排", "${p.used} 分钟", "${p.tasks.size} 项学习任务")
            metric("保留余量", "${m.planBudget.value - p.used} 分钟", "${p.skipped} 项因时间不足未安排")
        }.spacing(12.vp).height(112.vp)
        Panel {
            ScrollView {
                VStack {
                    heading("建议学习顺序")
                    var index: Int64 = 0
                    for (t in p.tasks) {
                        index++
                        let number = index
                        HStack {
                            Label("${number}").fontSize(22.fp).foregroundColor(Color.rgb(196, 53, 39)).width(36.vp)
                            VStack {
                                Label(t.title).fontSize(18.fp)
                                caption(if (isOverdue(t, m.planDate.value)) {"已逾期，优先处理"} else {"${priorityName(t.priority)}优先级 · ${t.subject}"})
                            }.spacing(5.vp).hug()
                            Spacer()
                            Label("${t.minutes} 分钟").fontSize(20.fp)
                        }.spacing(10.vp).hug().padding(12.vp)
                    }
                    if (p.tasks.isEmpty()) { caption("暂无能完整放入预算的任务，试试拆小任务或增加预算。") }
                    caption("这是简单的贪心建议，不保证最优或用满预算；完成任务后请到清单中标记。")
                }.spacing(13.vp).hug()
            }
        }.contentPadding(20.vp).flex()
    } else {
        Panel {
            VStack {
                heading("给时间设个范围，让学习有个顺序")
                caption("填写日期与可用分钟，点击上方按钮。任务清单发生修改后，需要重新生成建议。")
            }.spacing(12.vp).hug().padding(26.vp)
        }.flex()
    }
}

// 直接双击时打开 PPT 演示；脚本传 --data 时使用用户指定的独立任务文件。
func defaultDesktopData(demo: Bool): String {
    let file = if (demo) {"demo-tasks.tsv"} else {"tasks.tsv"}
    if (let Some(base) <- ApplicationPaths.basePath()) {
        var folder = Path(base)
        for (_ in 0..4) {
            if (exists(folder.join("cjpm.toml"))) { return folder.join("data").join(file).toString() }
            folder = folder.parent
        }
        return Path(base).join("data").join(file).toString()
    }
    return "data/" + file
}

main(args: Array<String>): Int64 {
    var path = ""
    var demo = args.isEmpty()
    var showPlan = args.isEmpty()
    var imeDiagnostics = false
    var i = 0
    while (i < args.size) {
        if (args[i] == "--demo") { demo = true }
        if (args[i] == "--show-plan") { showPlan = true }
        if (args[i] == "--ime-diagnostics") { imeDiagnostics = true }
        if (args[i] == "--data" && i + 1 < args.size) { i++; path = args[i] }
        i++
    }
    if (path.isEmpty()) { path = defaultDesktopData(demo) }
    try {
        let model = DesktopModel(path, demo)
        if (showPlan) { model.page.value = 1; model.generate() }
        let app = DesktopApp(WindowSpec("学伴 StudyMate — 仓颉学习任务助手", 1190, 780, scale: 1.0),
            theme: studyTheme(), hints: [SdlHintSetting(SdlHint.ImeImplementedUi, "none")])
        let ime = WindowsTextInput()
        app.manage(ime)
        app.setMinimumSize(1100, 720)
        let imeRecorded = State<Bool>(false)
        let diagnosticsEnabled = imeDiagnostics
        let dataPath = path
        app.run {
            subscribeFrame({_, _ =>
                ime.ensure()
                if (!imeRecorded.value) {
                    // 只记录本程序窗口的状态，不记录用户输入；日志失败不影响使用。
                    if (let Some(base) <- ApplicationPaths.basePath()) {
                        try { File.writeTo(base + "ime-status.log", ime.diagnostics().toArray()) }
                        catch (_: Exception) { () }
                    }
                    if (diagnosticsEnabled) {
                        try { File.writeTo(dataPath + ".ime.log", ime.diagnostics().toArray()) }
                        catch (_: Exception) { () }
                    }
                    imeRecorded.value = true
                }
            })
            appView(model)
        }
        return 0
    } catch (e: Exception) { println("桌面程序启动失败：${e.message}"); return 1 }
}
