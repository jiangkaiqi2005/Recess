package io.github.jiangkaiqi2005.recess

import java.time.LocalDate
import java.time.LocalDateTime

/**
 * 一条课次。由 Flutter 侧预先算好并写入 home_widget 的 SharedPreferences。
 *
 * [start] / [end] 为本地时间；任意一端拿不到时为空。
 */
data class WidgetOccurrence(
    val date: LocalDate,
    val start: LocalDateTime?,
    val end: LocalDateTime?,
    val startSection: Int,
    val endSection: Int,
    val name: String,
    val location: String,
    val colorLight: Int,
    val colorDark: Int
)

/** 某个日期的教学周。[week] 为 null 表示不在教学周内。 */
data class WidgetDay(
    val date: LocalDate,
    val week: Int?
)

/** 挑选结果：标题栏文字 + 今天还没结束的课次。 */
data class WidgetSelection(
    val title: String,
    val occurrences: List<WidgetOccurrence>
)

/**
 * 纯 Kotlin 挑选类，不依赖 Android 框架。
 *
 * 周次与课次都由 Dart 侧算好，这里只按传入的当前本地时间做筛选：
 * - 标题栏：教学周内显示「第 8 周 · 周四」，否则显示「10月23日 周四」；
 * - 今天的列表：日期为今天且结束时刻晚于现在；结束时刻缺失时当天一直保留。
 * - 时间冲突的课次全部保留，按开始时刻、开始节次、结束节次、课程名排序。
 *
 * 测试见 `src/test/java/io/github/jiangkaiqi2005/recess/WidgetSelectorTest.kt`。
 */
object WidgetSelector {

    private val weekdayLabels = listOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")

    private val occurrenceOrder = compareBy<WidgetOccurrence>(
        { it.start == null },
        { it.start },
        { it.startSection },
        { it.endSection },
        { it.name }
    )

    fun select(
        now: LocalDateTime,
        occurrences: List<WidgetOccurrence>,
        days: List<WidgetDay>
    ): WidgetSelection {
        val today = now.toLocalDate()
        val todayOccurrences = occurrences
            .filter { it.date == today && (it.end == null || it.end.isAfter(now)) }
            .sortedWith(occurrenceOrder)
        return WidgetSelection(
            title = titleFor(today, days),
            occurrences = todayOccurrences
        )
    }

    private fun titleFor(today: LocalDate, days: List<WidgetDay>): String {
        val weekday = weekdayLabels[today.dayOfWeek.value - 1]
        val week = days.firstOrNull { it.date == today }?.week
        return if (week != null && week > 0) {
            "第 $week 周 · $weekday"
        } else {
            "${today.monthValue}月${today.dayOfMonth}日 $weekday"
        }
    }
}
