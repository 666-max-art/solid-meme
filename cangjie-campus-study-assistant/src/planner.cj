package studymate

import std.collection.*

public class StudyPlan {
    public let tasks: ArrayList<StudyTask> = ArrayList<StudyTask>()
    public var used: Int64 = 0
    public var skipped: Int64 = 0
}

public func isOverdue(t: StudyTask, today: String): Bool {
    return !t.done && !t.due.isEmpty() && t.due < today
}

// 比较规则写成独立函数，便于解释和修改。
func comesFirst(a: StudyTask, b: StudyTask, today: String): Bool {
    if (isOverdue(a, today) != isOverdue(b, today)) { return isOverdue(a, today) }
    if (a.priority != b.priority) { return a.priority < b.priority }
    if (a.due != b.due) {
        if (a.due.isEmpty()) { return false }
        if (b.due.isEmpty()) { return true }
        return a.due < b.due
    }
    return a.id < b.id
}

public func orderedPending(book: TaskBook, today: String): ArrayList<StudyTask> {
    if (!validateDate(today)) { throw IllegalArgumentException("规划日期无效。") }
    let result = ArrayList<StudyTask>()
    // 插入排序：任务本规模较小，用清晰的循环代替复杂的排序框架。
    for (t in book.tasks) {
        if (t.done) { continue }
        result.add(t)
        var i = result.size - 1
        while (i > 0 && comesFirst(result[i], result[i - 1], today)) {
            let previous = result[i - 1]
            result[i - 1] = result[i]
            result[i] = previous
            i--
        }
    }
    return result
}

public func makePlan(book: TaskBook, today: String, budget: Int64): StudyPlan {
    if (budget < 1 || budget > 1440) { throw IllegalArgumentException("可用时间应为 1～1440 分钟。") }
    let plan = StudyPlan()
    for (t in orderedPending(book, today)) {
        if (t.minutes <= budget - plan.used) {
            plan.tasks.add(t)
            plan.used += t.minutes
        } else {
            plan.skipped++
        }
    }
    return plan
}

public func priorityName(value: Int64): String {
    match (value) {
        case 1 => return "高"
        case 2 => return "中"
        case _ => return "低"
    }
}

func markdownText(text: String): String {
    // HTML 转义让用户标题不能在报告里变成图片、链接或 HTML。
    var value = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    for (symbol in ["\\", "`", "*", "_", "[", "]", "|", "~"]) {
        value = value.replace(symbol, "\\" + symbol)
    }
    return value
}

public func makeReport(book: TaskBook, today: String, budget: Int64): String {
    let plan = makePlan(book, today, budget)
    var done: Int64 = 0
    var pendingMinutes: Int64 = 0
    for (t in book.tasks) {
        if (t.done) { done++ } else { pendingMinutes += t.minutes }
    }
    var text = "# 学伴学习报告\n\n日期：${today}\n\n"
    text += "- 任务总数：${book.tasks.size}\n- 已完成：${done}\n"
    text += "- 待完成预计用时：${pendingMinutes} 分钟\n"
    text += "- 今日预算：${budget} 分钟；安排：${plan.used} 分钟；剩余：${budget - plan.used} 分钟\n\n"
    text += "## 今日建议\n\n| 编号 | 任务 | 科目 | 分钟 | 优先级 | 截止日期 |\n| --- | --- | --- | --- | --- | --- |\n"
    for (t in plan.tasks) {
        let due = if (t.due.isEmpty()) { "无" } else { t.due }
        text += "| ${t.id} | ${markdownText(t.title)} | ${markdownText(t.subject)} | ${t.minutes} | ${priorityName(t.priority)} | ${due} |\n"
    }
    if (plan.tasks.isEmpty()) { text += "\n当前没有能完整放入预算的待办任务。\n" }
    text += "\n有 ${plan.skipped} 项任务因剩余时间不足未安排。可先把大任务拆小。\n"
    text += "\n规则：逾期优先，再按优先级、截止日期、编号排序；依次选择能完整放入预算的任务。"
    text += "这是简单的贪心建议，不保证全局最优；计划不会自动标记任务完成。\n\n"
    text += "## 全部任务\n\n| 编号 | 状态 | 任务 | 科目 | 预计分钟 |\n| --- | --- | --- | --- | --- |\n"
    for (t in book.tasks) {
        let state = if (t.done) { "已完成" } else { "待完成" }
        text += "| ${t.id} | ${state} | ${markdownText(t.title)} | ${markdownText(t.subject)} | ${t.minutes} |\n"
    }
    text += "\n这里的用时是用户填写的预计值，不是专注计时记录。\n"
    return text
}
