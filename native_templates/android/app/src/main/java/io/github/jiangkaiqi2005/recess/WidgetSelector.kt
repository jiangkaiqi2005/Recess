package io.github.jiangkaiqi2005.recess

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.TemporalAdjusters

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

/** 小组件当前要显示的内容。 */
enum class WidgetDisplayMode {
    /** 今天还有结束时刻晚于现在的课次（任一端钟点缺失时整个当天保留）。 */
    TODAY,

    /** 今天没有剩余课次，但今天之后还有课次。 */
    NEXT,

    /** 已加载过数据，但本学期剩余时间里已经没有课次。 */
    SEMESTER_ENDED,

    /** 从未成功写入过数据。 */
    NOT_LOADED
}

/**
 * 挑选结果。
 *
 * [occurrences] 在 [WidgetDisplayMode.TODAY] 下是今天剩余的课次，在
 * [WidgetDisplayMode.NEXT] 下只有一条下一节课；两种空状态下为空。
 * [capsule] 只在 [WidgetDisplayMode.NEXT] 下有值。
 * [nextRefresh] 是下一次需要刷新小组件的本地时刻，一定晚于传入的现在。
 */
data class WidgetSelection(
    val title: String,
    val mode: WidgetDisplayMode,
    val occurrences: List<WidgetOccurrence>,
    val nextRefresh: LocalDateTime,
    val capsule: String? = null
)

/**
 * 纯 Kotlin 挑选类，不依赖 Android 框架。
 *
 * 周次与课次都由 Dart 侧算好，这里只按传入的当前本地时间挑选：
 * - 标题栏：教学周内显示「第 8 周 · 周四」，否则显示「10月23日 周四」；
 * - 今天的列表：日期为今天且结束时刻晚于现在；任一端钟点缺失时整个当天
 *   一直保留。有完整钟点的课次排在前，按开始时刻、节次、课程名排序；缺钟点
 *   的课次排在后，按节次、课程名排序；
 * - 下一节课：今天之后最早的那一天里的第一节课，今天已结束的课次不参与；
 *   按节次优先，取开始节次、结束节次、课程名最靠前的一节，不比较开始时刻；
 * - 胶囊文字：明天写「明天 · 周X」，本周内写「周X」，下一周写「下周X」，
 *   更远写「M月D日」；
 * - 下一次刷新：今天剩余课次中最近的开始或结束时刻，与下一个零点取较早者；
 *   今天没有剩余课次、没有数据或学期结束时就是下一个零点。
 *
 * 测试见 `src/test/java/io/github/jiangkaiqi2005/recess/WidgetSelectorTest.kt`。
 */
object WidgetSelector {

    private val weekdayNames = listOf("一", "二", "三", "四", "五", "六", "日")

    /** 今天的列表：完整钟点在前（按开始时刻、节次、课程名），缺钟点在后（按节次、课程名）。 */
    private val todayOrder = compareBy<WidgetOccurrence>(
        { it.start == null || it.end == null },
        { if (it.start != null && it.end != null) it.start else null },
        { it.startSection },
        { it.endSection },
        { it.name }
    )

    /** 下一节课：按开始节次、结束节次、课程名排序，不比较开始时刻。 */
    private val sectionOrder = compareBy<WidgetOccurrence>(
        { it.startSection },
        { it.endSection },
        { it.name }
    )

    fun select(
        now: LocalDateTime,
        occurrences: List<WidgetOccurrence>,
        days: List<WidgetDay>,
        loaded: Boolean
    ): WidgetSelection {
        val today = now.toLocalDate()
        val title = titleFor(today, days)
        val midnight = today.plusDays(1).atStartOfDay()
        if (!loaded) {
            return WidgetSelection(
                title = title,
                mode = WidgetDisplayMode.NOT_LOADED,
                occurrences = emptyList(),
                nextRefresh = midnight
            )
        }

        val todayOccurrences = occurrences
            .filter {
                it.date == today &&
                    (it.start == null || it.end == null || it.end.isAfter(now))
            }
            .sortedWith(todayOrder)
        if (todayOccurrences.isNotEmpty()) {
            return WidgetSelection(
                title = title,
                mode = WidgetDisplayMode.TODAY,
                occurrences = todayOccurrences,
                nextRefresh = nextRefreshAt(now, occurrences, midnight)
            )
        }

        val next = nextAfter(today, occurrences)
            ?: return WidgetSelection(
                title = title,
                mode = WidgetDisplayMode.SEMESTER_ENDED,
                occurrences = emptyList(),
                nextRefresh = midnight
            )
        return WidgetSelection(
            title = title,
            mode = WidgetDisplayMode.NEXT,
            occurrences = listOf(next),
            nextRefresh = nextRefreshAt(now, occurrences, midnight),
            capsule = capsuleFor(today, next.date)
        )
    }

    /**
     * 下一次刷新时刻：今天剩余课次中最近的开始或结束时刻，与下一个零点取较早者。
     *
     * 今天已结束的课次不会产生晚于现在的时刻，因此不必再判断是否剩余；缺少任意
     * 一端时只按已知的另一端参与，两端都缺失的课次不产生候选。结果一定晚于现在。
     */
    private fun nextRefreshAt(
        now: LocalDateTime,
        occurrences: List<WidgetOccurrence>,
        midnight: LocalDateTime
    ): LocalDateTime {
        val today = now.toLocalDate()
        val nextMoment = occurrences
            .filter { it.date == today }
            .flatMap { listOf(it.start, it.end) }
            .filterNotNull()
            .filter { it.isAfter(now) }
            .minOrNull()
        return if (nextMoment != null && nextMoment.isBefore(midnight)) {
            nextMoment
        } else {
            midnight
        }
    }

    /**
     * 今天之后最早的一天里的第一节课。
     *
     * 按节次优先：先取最早的日期，再按开始节次、结束节次、课程名排序取第一节，
     * 不比较开始时刻。因此第 1-2 节没有钟点、第 5-6 节有钟点时，仍取第 1-2 节。
     * 这个规则由单测固定，见 `WidgetSelectorTest` 的下一节课用例。
     */
    private fun nextAfter(
        today: LocalDate,
        occurrences: List<WidgetOccurrence>
    ): WidgetOccurrence? {
        val nextDate = occurrences
            .asSequence()
            .map { it.date }
            .filter { it.isAfter(today) }
            .minOrNull()
            ?: return null
        return occurrences
            .filter { it.date == nextDate }
            .sortedWith(sectionOrder)
            .firstOrNull()
    }

    private fun capsuleFor(today: LocalDate, next: LocalDate): String {
        val weekday = weekdayNames[next.dayOfWeek.value - 1]
        // 明天优先于「下周X」：即使明天是下周一，也写「明天 · 周一」。
        if (next == today.plusDays(1)) {
            return "明天 · 周$weekday"
        }
        val thisMonday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val nextMonday = next.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        return when (nextMonday) {
            thisMonday -> "周$weekday"
            thisMonday.plusWeeks(1) -> "下周$weekday"
            else -> "${next.monthValue}月${next.dayOfMonth}日"
        }
    }

    private fun titleFor(today: LocalDate, days: List<WidgetDay>): String {
        val weekday = "周${weekdayNames[today.dayOfWeek.value - 1]}"
        val week = days.firstOrNull { it.date == today }?.week
        return if (week != null && week > 0) {
            "第 $week 周 · $weekday"
        } else {
            "${today.monthValue}月${today.dayOfMonth}日 $weekday"
        }
    }
}
