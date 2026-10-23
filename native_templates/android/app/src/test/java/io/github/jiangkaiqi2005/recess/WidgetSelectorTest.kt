package io.github.jiangkaiqi2005.recess

import java.time.LocalDate
import java.time.LocalDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [WidgetSelector] 的 JVM 单测，只依赖纯 Kotlin 挑选类。
 *
 * 这些测试随 `native_templates/android/app/src/test/` 复制进本地 `android/`
 * 后运行 `./gradlew :app:testDebugUnitTest`；CI 不生成 `android/` 目录，
 * 因此 CI 不覆盖这部分。
 */
class WidgetSelectorTest {

    private val thursday = LocalDate.of(2026, 10, 22)

    private fun occurrence(
        name: String,
        start: String?,
        end: String?,
        startSection: Int = 1,
        endSection: Int = 2,
        date: LocalDate = thursday
    ) = WidgetOccurrence(
        date = date,
        start = start?.let { LocalDateTime.parse("${date}T$it") },
        end = end?.let { LocalDateTime.parse("${date}T$it") },
        startSection = startSection,
        endSection = endSection,
        name = name,
        location = "",
        colorLight = 0xFF4399F1.toInt(),
        colorDark = 0xFF217BD1.toInt()
    )

    private fun teachingDays(week: Int = 7) = listOf(WidgetDay(thursday, week))

    @Test
    fun `正在上课时保留当前课次并显示教学周标题`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 9, 0),
            occurrences = listOf(occurrence("高等数学", "08:00", "09:40")),
            days = teachingDays()
        )

        assertEquals("第 7 周 · 周四", selection.title)
        assertEquals(listOf("高等数学"), selection.occurrences.map { it.name })
    }

    @Test
    fun `两节课之间只显示尚未结束的课次`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 10, 0),
            occurrences = listOf(
                occurrence("上午课", "08:00", "09:40"),
                occurrence("下午课", "14:00", "15:40", startSection = 5, endSection = 6)
            ),
            days = teachingDays()
        )

        assertEquals(listOf("下午课"), selection.occurrences.map { it.name })
    }

    @Test
    fun `今天最后一节下课后不再显示课次`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 16, 0),
            occurrences = listOf(
                occurrence("上午课", "08:00", "09:40"),
                occurrence("最后一节", "14:00", "15:40", startSection = 5, endSection = 6)
            ),
            days = teachingDays()
        )

        assertTrue(selection.occurrences.isEmpty())
    }

    @Test
    fun `结束时刻恰好等于现在时视为已结束`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 9, 40),
            occurrences = listOf(occurrence("高等数学", "08:00", "09:40")),
            days = teachingDays()
        )

        assertTrue(selection.occurrences.isEmpty())
    }

    @Test
    fun `缺少钟点的课次当天一直保留并按节次排序`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 21, 0),
            occurrences = listOf(
                occurrence("缺钟点后", null, null, startSection = 11, endSection = 12),
                occurrence("已下课", "08:00", "09:40"),
                occurrence("缺钟点前", null, null, startSection = 3, endSection = 4),
                occurrence("只缺结束", "19:00", null, startSection = 9, endSection = 10)
            ),
            days = teachingDays()
        )

        assertEquals(
            listOf("只缺结束", "缺钟点前", "缺钟点后"),
            selection.occurrences.map { it.name }
        )
    }

    @Test
    fun `标题栏按逐日映射显示教学周或日期`() {
        val friday = LocalDate.of(2026, 10, 23)
        val now = LocalDateTime.of(2026, 10, 23, 10, 0)

        val inTeachingWeek = WidgetSelector.select(
            now = now,
            occurrences = emptyList(),
            days = listOf(WidgetDay(friday, 7))
        )
        assertEquals("第 7 周 · 周五", inTeachingWeek.title)

        val outsideTeachingWeek = WidgetSelector.select(
            now = now,
            occurrences = emptyList(),
            days = listOf(WidgetDay(friday, null))
        )
        assertEquals("10月23日 周五", outsideTeachingWeek.title)

        val noMapping = WidgetSelector.select(
            now = now,
            occurrences = emptyList(),
            days = emptyList()
        )
        assertEquals("10月23日 周五", noMapping.title)
    }

    @Test
    fun `没有任何数据时返回空列表和日期标题`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 10, 0),
            occurrences = emptyList(),
            days = emptyList()
        )

        assertTrue(selection.occurrences.isEmpty())
        assertEquals("10月22日 周四", selection.title)
    }

    @Test
    fun `时间冲突的课次全部保留并按开始时刻与节次排序`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 7, 0),
            occurrences = listOf(
                occurrence("冲突B", "08:00", "09:40", startSection = 3, endSection = 4),
                occurrence("冲突A", "08:00", "09:40", startSection = 1, endSection = 2),
                occurrence("稍后", "09:00", "10:40", startSection = 5, endSection = 6)
            ),
            days = teachingDays()
        )

        assertEquals(listOf("冲突A", "冲突B", "稍后"), selection.occurrences.map { it.name })
    }
}
