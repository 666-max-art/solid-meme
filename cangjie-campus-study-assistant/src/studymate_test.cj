package studymate

import std.collection.*

// 所有日期和预算都由测试给定，不依赖运行机器的时钟或用户数据文件。
func rejectsAdd(book: TaskBook, title: String, subject: String,
    minutes: Int64, priority: Int64, due: String): Bool {
    try {
        book.add(title, subject, minutes, priority, due)
        return false
    } catch (_: IllegalArgumentException) {
        return true
    }
}

func rejectsDecode(text: String): Bool {
    try {
        let _ = decodeBook(text)
        return false
    } catch (_: Exception) {
        return true
    }
}

@Test
func datesRespectCalendarAndLeapYearRules(): Unit {
    @Expect(validateDate("2024-02-29"))
    @Expect(validateDate("2000-02-29"))
    @Expect(!validateDate("1900-02-29"))
    @Expect(!validateDate("2026-02-29"))
    @Expect(!validateDate("2026-04-31"))
    @Expect(!validateDate("2026-00-10"))
    @Expect(!validateDate("2026-10-00"))
    @Expect(!validateDate("2026-1-07"))
    @Expect(!validateDate("2026-xx-07"))
    @Expect(!validateDate("1899-12-31"))
}

@Test
func addTrimsTextAndRejectsBadInputWithoutConsumingAnId(): Unit {
    let book = TaskBook()
    @Expect(rejectsAdd(book, "   ", "仓颉", 25, 2, ""))
    @Expect(rejectsAdd(book, "练习\t一", "仓颉", 25, 2, ""))
    @Expect(rejectsAdd(book, "练习", "", 25, 2, ""))
    @Expect(rejectsAdd(book, "练习", "仓颉", 25, 2, "2026-02-30"))
    @Expect(book.tasks.size, 0)
    @Expect(book.nextId, 1)
    book.add("  复习枚举  ", " 仓颉 ", 25, 2, "")
    @Expect(book.tasks[0].title, "复习枚举")
    @Expect(book.tasks[0].subject, "仓颉")
    @Expect(book.tasks[0].id, 1)
}

@Test
func minutesAndPriorityEnforceTheirAllowedRanges(): Unit {
    let book = TaskBook()
    @Expect(rejectsAdd(book, "任务", "课程", 0, 2, ""))
    @Expect(rejectsAdd(book, "任务", "课程", 1441, 2, ""))
    @Expect(rejectsAdd(book, "任务", "课程", 30, 0, ""))
    @Expect(rejectsAdd(book, "任务", "课程", 30, 4, ""))
    book.add("最短任务", "课程", 1, 1, "")
    book.add("最长任务", "课程", 1440, 3, "")
    @Expect(book.tasks.size, 2)
}

@Test
func deletingAMissingTaskPreservesExistingData(): Unit {
    let book = TaskBook()
    book.add("已有任务", "课程", 30, 2, "")
    var rejected = false
    try { book.delete(99) } catch (_: IllegalArgumentException) { rejected = true }
    @Expect(rejected)
    @Expect(book.tasks.size, 1)
    @Expect(book.tasks[0].title, "已有任务")
    @Expect(book.nextId, 2)
}

@Test
func deletedIdentifiersAreNeverReused(): Unit {
    let book = TaskBook()
    book.add("第一项", "课程", 10, 2, "")
    book.add("第二项", "课程", 20, 2, "")
    book.delete(2)
    book.add("第三项", "课程", 30, 2, "")
    @Expect(book.tasks[1].id, 3)
    @Expect(book.nextId, 4)
    book.setDone(1, true)
    @Expect(book.tasks[0].done)
    book.setDone(1, false)
    @Expect(!book.tasks[0].done)
}

@Test
func aWorkingCopyCanChangeWithoutChangingItsSource(): Unit {
    let original = TaskBook()
    original.add("保留任务", "课程", 30, 2, "")
    let copy = original.copyBook()
    copy.setDone(1, true)
    copy.add("副本新增", "课程", 10, 1, "")
    @Expect(original.tasks.size, 1)
    @Expect(!original.tasks[0].done)
    @Expect(original.nextId, 2)
    @Expect(copy.tasks.size, 2)
    @Expect(copy.tasks[0].done)
    copy.delete(1)
    @Expect(original.tasks[0].id, 1)
    @Expect(copy.tasks[0].id, 2)
}

@Test
func overdueTasksComeFirstThenPriorityAndDeadline(): Unit {
    let book = TaskBook()
    book.add("未来高优先", "课程", 10, 1, "2026-10-10")
    book.add("逾期低优先", "课程", 10, 3, "2026-10-06")
    book.add("逾期高优先", "课程", 10, 1, "2026-10-05")
    book.add("今天高优先", "课程", 10, 1, "2026-10-07")
    let ordered = orderedPending(book, "2026-10-07")
    @Expect(ordered[0].id, 3)
    @Expect(ordered[1].id, 2)
    @Expect(ordered[2].id, 4)
    @Expect(ordered[3].id, 1)
    @Expect(!isOverdue(book.tasks[3], "2026-10-07"))
}

@Test
func equalTasksWithoutDeadlinesUseIdentifierOrder(): Unit {
    let tasks = ArrayList<StudyTask>()
    tasks.add(StudyTask(8, "后编号", "课程", 10, 2, "", false))
    tasks.add(StudyTask(3, "前编号", "课程", 10, 2, "", false))
    tasks.add(StudyTask(5, "有期限", "课程", 10, 2, "2026-10-09", false))
    let ordered = orderedPending(TaskBook(tasks, 9), "2026-10-07")
    @Expect(ordered[0].id, 5)
    @Expect(ordered[1].id, 3)
    @Expect(ordered[2].id, 8)
}

@Test
func aPlanFitsWholeTasksWithinTheExactBudget(): Unit {
    let book = TaskBook()
    book.add("先做", "课程", 20, 1, "")
    book.add("再做", "课程", 30, 2, "")
    book.add("留到以后", "课程", 10, 3, "")
    let plan = makePlan(book, "2026-10-07", 50)
    @Expect(plan.tasks.size, 2)
    @Expect(plan.used, 50)
    @Expect(plan.skipped, 1)
    var total: Int64 = 0
    for (task in plan.tasks) { total += task.minutes }
    @Expect(total, plan.used)
    @Expect(total <= 50)
    @Expect(!book.tasks[0].done)
}

@Test
func aLongSkippedTaskDoesNotBlockAShorterTask(): Unit {
    let book = TaskBook()
    book.add("长任务", "课程", 90, 1, "")
    book.add("短任务", "课程", 20, 2, "")
    let plan = makePlan(book, "2026-10-07", 30)
    @Expect(plan.tasks.size, 1)
    @Expect(plan.tasks[0].id, 2)
    @Expect(plan.used, 20)
    @Expect(plan.skipped, 1)
}

@Test
func completedTasksAreExcludedFromPlans(): Unit {
    let book = TaskBook()
    book.add("完成的逾期任务", "课程", 25, 1, "2026-10-01")
    book.add("待完成任务", "课程", 15, 3, "")
    book.setDone(1, true)
    let plan = makePlan(book, "2026-10-07", 30)
    @Expect(plan.tasks.size, 1)
    @Expect(plan.tasks[0].id, 2)
    @Expect(plan.used, 15)
    @Expect(plan.skipped, 0)
    @Expect(!isOverdue(book.tasks[0], "2026-10-07"))
}

@Test
func storageRoundTripPreservesChineseEmptyDeadlineAndNextId(): Unit {
    let book = TaskBook()
    book.add("复习仓颉泛型", "程序设计", 35, 1, "2026-10-09")
    book.add("练习高数积分", "高等数学", 45, 2, "")
    book.add("删除后也要记住编号", "课程", 10, 3, "")
    book.setDone(1, true)
    book.delete(3)
    let loaded = decodeBook(encodeBook(book))
    @Expect(loaded.tasks.size, 2)
    @Expect(loaded.nextId, 4)
    @Expect(loaded.tasks[0].title, "复习仓颉泛型")
    @Expect(loaded.tasks[0].subject, "程序设计")
    @Expect(loaded.tasks[0].minutes, 35)
    @Expect(loaded.tasks[0].done)
    @Expect(loaded.tasks[0].due, "2026-10-09")
    @Expect(loaded.tasks[1].due, "")
    loaded.add("恢复后新增", "仓颉", 20, 2, "")
    @Expect(loaded.tasks[2].id, 4)
}

@Test
func storageAcceptsWindowsLineEndings(): Unit {
    let book = TaskBook()
    book.add("Windows 数据", "仓颉", 30, 2, "")
    let crlf = encodeBook(book).replace("\r\n", "\n").replace("\n", "\r\n")
    let loaded = decodeBook(crlf)
    @Expect(loaded.tasks.size, 1)
    @Expect(loaded.tasks[0].title, "Windows 数据")
    @Expect(loaded.tasks[0].due, "")
}

@Test
func corruptedRecordsDuplicateIdsAndInvalidNextIdsAreRejected(): Unit {
    let validRow = "1\t复习\t仓颉\t30\t2\t\t0\n"
    @Expect(rejectsDecode(""))
    @Expect(rejectsDecode("# unknown-version\t2\n" + validRow))
    @Expect(rejectsDecode("# studymate-v1\t2\n1\t缺列\t仓颉\t30\t2\t0\n"))
    @Expect(rejectsDecode("# studymate-v1\t2\n1\t复习\t仓颉\t30\t2\t\ttrue\n"))
    @Expect(rejectsDecode("# studymate-v1\t2\n" + validRow + validRow))
    @Expect(rejectsDecode("# studymate-v1\t0\n"))
    @Expect(rejectsDecode("# studymate-v1\t1\n" + validRow))
    @Expect(rejectsDecode("# studymate-v1\t1000000001\n"))
    @Expect(rejectsDecode("# studymate-v1\t2\n\n" + validRow))
}

@Test
func reportsEscapeUserTextInBothMarkdownTables(): Unit {
    let book = TaskBook()
    book.add("[链接](x) | `代码` *重点* <img> &", "高数_练习", 20, 1, "")
    let report = makeReport(book, "2026-10-07", 30)
    let escapedTitle = "\\[链接\\](x) \\| \\`代码\\` \\*重点\\* &lt;img&gt; &amp;"
    @Expect(report.split(escapedTitle).size, 3)
    @Expect(report.split("高数\\_练习").size, 3)
    @Expect(!report.contains("<img>"))
    @Expect(report.contains("安排：20 分钟；剩余：10 分钟"))
}
