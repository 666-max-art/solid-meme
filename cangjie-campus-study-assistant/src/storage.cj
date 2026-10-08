package studymate

import std.collection.*
import std.convert.*
import std.fs.*

// 保存和读取都使用同一组校验，避免把损坏数据当成空任务本。
func validateBook(book: TaskBook): Unit {
    if (book.nextId < 1 || book.nextId > 1000000000) {
        throw IllegalArgumentException("任务本中的下一个编号不合法。")
    }
    if (book.tasks.size > 1000) {
        throw IllegalArgumentException("任务本最多保存 1000 条任务。")
    }
    let seen = HashSet<Int64>()
    var largestId: Int64 = 0
    for (task in book.tasks) {
        validateTask(task)
        if (seen.contains(task.id)) {
            throw IllegalArgumentException("任务本中出现重复编号 ${task.id}。")
        }
        seen.add(task.id)
        if (task.id > largestId) { largestId = task.id }
    }
    if (book.nextId <= largestId) {
        throw IllegalArgumentException("下一个编号必须大于全部已有任务编号。")
    }
}

// 存储格式只接受普通十进制整数，拒绝溢出、空串和多余字符。
func storedNumber(text: String, row: Int64): Int64 {
    match (Int64.tryParse(text)) {
        case Some(value) =>
            if (value.toString() != text) {
                throw IllegalArgumentException("数据文件第 ${row} 行的整数格式不正确。")
            }
            return value
        case None => throw IllegalArgumentException("数据文件第 ${row} 行包含无效整数。")
    }
}

public func encodeBook(book: TaskBook): String {
    validateBook(book)
    var text = "# studymate-v1\t${book.nextId}\n"
    for (task in book.tasks) {
        let state = if (task.done) { "1" } else { "0" }
        text += "${task.id}\t${task.title}\t${task.subject}\t${task.minutes}\t${task.priority}\t${task.due}\t${state}\n"
    }
    return text
}

public func decodeBook(text: String): TaskBook {
    // Windows 的 CRLF 和其它平台的 LF 都可以读取。
    let lines = text.replace("\r\n", "\n").split("\n")
    if (lines.isEmpty()) {
        throw IllegalArgumentException("数据文件为空，缺少任务本格式标记。")
    }
    let header = lines[0].split("\t")
    if (header.size != 2 || header[0] != "# studymate-v1") {
        throw IllegalArgumentException("数据文件的格式标记不正确，应为 studymate-v1。")
    }
    let nextId = storedNumber(header[1], 1)
    let tasks = ArrayList<StudyTask>()
    for (i in 1..lines.size) {
        let row = i + 1
        // 只允许文件末尾的一个换行；文件中间的空行也算损坏。
        if (lines[i].isEmpty() && i == lines.size - 1) { continue }
        let fields = lines[i].split("\t")
        if (fields.size != 7) {
            throw IllegalArgumentException("数据文件第 ${row} 行应包含 7 列。")
        }
        if (tasks.size >= 1000) {
            throw IllegalArgumentException("任务本最多保存 1000 条任务。")
        }
        if (fields[6] != "0" && fields[6] != "1") {
            throw IllegalArgumentException("数据文件第 ${row} 行的完成状态应为 0 或 1。")
        }
        let task = StudyTask(storedNumber(fields[0], row), fields[1], fields[2],
            storedNumber(fields[3], row), storedNumber(fields[4], row), fields[5], fields[6] == "1")
        tasks.add(task)
    }
    let book = TaskBook(tasks, nextId)
    validateBook(book)
    return book
}

public func loadBook(path: String): TaskBook {
    if (!exists(path)) { return TaskBook() }
    // fromUtf8 会检查编码；非法编码或格式错误会向调用者报告。
    return decodeBook(String.fromUtf8(File.readFrom(path)))
}

public func saveBook(path: String, book: TaskBook): Unit {
    // 先完整验证，确认数据合法后才开始修改文件。
    let text = encodeBook(book)
    let parent = Path(path).parent
    if (!parent.toString().isEmpty() && !exists(parent)) {
        Directory.create(parent, recursive: true)
    }
    // 保留上一次内容；这是普通备份写入，不承诺原子保存。
    if (exists(path)) {
        File.writeTo(path + ".bak", File.readFrom(path))
    }
    File.writeTo(path, text.toArray())
}
