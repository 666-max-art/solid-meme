package studymate

import std.collection.*
import std.convert.*

// 一个对象就是一项任务；修改任务时用新对象替换，便于先保存再更新界面。
public class StudyTask {
    public let id: Int64
    public let title: String
    public let subject: String
    public let minutes: Int64
    public let priority: Int64
    public let due: String
    public let done: Bool

    public init(id: Int64, title: String, subject: String, minutes: Int64,
        priority: Int64, due: String, done: Bool) {
        this.id = id
        this.title = title
        this.subject = subject
        this.minutes = minutes
        this.priority = priority
        this.due = due
        this.done = done
    }
}

public class TaskBook {
    public let tasks: ArrayList<StudyTask>
    public var nextId: Int64

    public init() {
        this.tasks = ArrayList<StudyTask>()
        this.nextId = 1
    }

    public init(tasks: ArrayList<StudyTask>, nextId: Int64) {
        this.tasks = tasks
        this.nextId = nextId
    }

    public func copyBook(): TaskBook {
        return TaskBook(ArrayList<StudyTask>(tasks), nextId)
    }

    public func findIndex(id: Int64): Int64 {
        for (i in 0..tasks.size) {
            if (tasks[i].id == id) { return i }
        }
        throw IllegalArgumentException("没有编号为 ${id} 的任务。")
    }

    public func add(title: String, subject: String, minutes: Int64, priority: Int64, due: String): Unit {
        if (tasks.size >= 1000 || nextId >= 1000000000) {
            throw IllegalArgumentException("任务本最多保存 1000 条任务，编号上限为 999999999。")
        }
        let task = StudyTask(nextId, title.trimAscii(), subject.trimAscii(), minutes, priority, due, false)
        validateTask(task)
        tasks.add(task)
        nextId++
    }

    public func setDone(id: Int64, done: Bool): Unit {
        let i = findIndex(id)
        let t = tasks[i]
        tasks[i] = StudyTask(t.id, t.title, t.subject, t.minutes, t.priority, t.due, done)
    }

    public func delete(id: Int64): Unit {
        tasks.remove(at: findIndex(id))
    }
}

public func readNumber(text: String): Int64 {
    match (Int64.tryParse(text)) {
        case Some(value) => return value
        case None => throw IllegalArgumentException("请输入有效整数。")
    }
}

// ISO 日期可以直接按字符串比较；这里另外检查每个月真实的天数。
public func validateDate(text: String): Bool {
    let bytes = text.toArray()
    if (bytes.size != 10 || bytes[4] != 45 || bytes[7] != 45) { return false }
    for (i in 0..10) {
        if (i != 4 && i != 7 && (bytes[i] < 48 || bytes[i] > 57)) { return false }
    }
    let parts = text.split("-")
    let year = readNumber(parts[0])
    let month = readNumber(parts[1])
    let day = readNumber(parts[2])
    if (year < 1900 || year > 9999 || month < 1 || month > 12) { return false }
    var days: Int64 = 31
    if (month == 4 || month == 6 || month == 9 || month == 11) { days = 30 }
    if (month == 2) {
        days = 28
        if (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) { days = 29 }
    }
    return day >= 1 && day <= days
}

func validText(text: String, limit: Int64): Bool {
    if (text.trimAscii().isEmpty() || text.size > limit) { return false }
    // TSV 使用制表符和换行分列分行；也拒绝其它控制字符。
    for (b in text.toArray()) {
        if (b < 32 || b == 127) { return false }
    }
    return true
}

public func validateTask(t: StudyTask): Unit {
    if (t.id < 1 || t.id >= 1000000000) { throw IllegalArgumentException("任务编号不合法。") }
    if (!validText(t.title, 240)) { throw IllegalArgumentException("标题不能为空，最长 240 个 UTF-8 字节，不能有控制字符。") }
    if (!validText(t.subject, 96)) { throw IllegalArgumentException("科目不能为空，最长 96 个 UTF-8 字节，不能有控制字符。") }
    if (t.minutes < 1 || t.minutes > 1440) { throw IllegalArgumentException("预计时间应为 1～1440 分钟。") }
    if (t.priority < 1 || t.priority > 3) { throw IllegalArgumentException("优先级应为 1、2 或 3。") }
    if (!t.due.isEmpty() && !validateDate(t.due)) { throw IllegalArgumentException("日期应为有效的 YYYY-MM-DD，例如 2026-10-10。") }
}
