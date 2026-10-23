package io.github.jiangkaiqi2005.recess

import java.time.LocalDate
import java.time.LocalDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
            days = teachingDays(),
            loaded = true
        )

        assertEquals("第 7 周 · 周四", selection.title)
        assertEquals(WidgetDisplayMode.TODAY, selection.mode)
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
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.TODAY, selection.mode)
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
            days = teachingDays(),
            loaded = true
        )

        assertTrue(selection.occurrences.isEmpty())
        assertEquals(WidgetDisplayMode.SEMESTER_ENDED, selection.mode)
    }

    @Test
    fun `结束时刻恰好等于现在时视为已结束`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 9, 40),
            occurrences = listOf(occurrence("高等数学", "08:00", "09:40")),
            days = teachingDays(),
            loaded = true
        )

        assertTrue(selection.occurrences.isEmpty())
        assertEquals(WidgetDisplayMode.SEMESTER_ENDED, selection.mode)
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
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.TODAY, selection.mode)
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
            days = listOf(WidgetDay(friday, 7)),
            loaded = true
        )
        assertEquals("第 7 周 · 周五", inTeachingWeek.title)

        val outsideTeachingWeek = WidgetSelector.select(
            now = now,
            occurrences = emptyList(),
            days = listOf(WidgetDay(friday, null)),
            loaded = true
        )
        assertEquals("10月23日 周五", outsideTeachingWeek.title)

        val noMapping = WidgetSelector.select(
            now = now,
            occurrences = emptyList(),
            days = emptyList(),
            loaded = true
        )
        assertEquals("10月23日 周五", noMapping.title)
    }

    @Test
    fun `已加载但没有课次时显示本学期已结束`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 10, 0),
            occurrences = emptyList(),
            days = emptyList(),
            loaded = true
        )

        assertTrue(selection.occurrences.isEmpty())
        assertEquals(WidgetDisplayMode.SEMESTER_ENDED, selection.mode)
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
            days = teachingDays(),
            loaded = true
        )

        assertEquals(listOf("冲突A", "冲突B", "稍后"), selection.occurrences.map { it.name })
    }

    @Test
    fun `周四晚上显示下一节课并标注明天`() {
        val friday = thursday.plusDays(1)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 21, 0),
            occurrences = listOf(
                occurrence("已下课", "08:00", "09:40"),
                occurrence("线性代数", "08:00", "09:40", date = friday)
            ),
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("明天 · 周五", selection.capsule)
        assertEquals(listOf("线性代数"), selection.occurrences.map { it.name })
    }

    @Test
    fun `周五晚上下一节课在下一周时写下周`() {
        val friday = LocalDate.of(2026, 10, 23)
        val monday = LocalDate.of(2026, 10, 26)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 23, 20, 0),
            occurrences = listOf(
                occurrence("线性代数", "08:00", "09:40", date = monday)
            ),
            days = listOf(WidgetDay(friday, 7)),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("下周一", selection.capsule)
    }

    @Test
    fun `周日晚上下一节课在周一时明天优先于下周`() {
        val sunday = LocalDate.of(2026, 10, 25)
        val monday = LocalDate.of(2026, 10, 26)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 25, 20, 0),
            occurrences = listOf(
                occurrence("线性代数", "08:00", "09:40", date = monday)
            ),
            days = listOf(WidgetDay(sunday, 7)),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("明天 · 周一", selection.capsule)
    }

    @Test
    fun `本周内隔天的下一节课写星期几`() {
        val saturday = LocalDate.of(2026, 10, 24)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 21, 0),
            occurrences = listOf(
                occurrence("大学物理", "08:00", "09:40", date = saturday)
            ),
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("周六", selection.capsule)
    }

    @Test
    fun `跨多周的假期写月日且不带星期`() {
        val holidayEnd = LocalDate.of(2026, 11, 3)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 21, 0),
            occurrences = listOf(
                occurrence("大学物理", "08:00", "09:40", date = holidayEnd)
            ),
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("11月3日", selection.capsule)
    }

    @Test
    fun `开学前显示开学后的第一节课`() {
        val now = LocalDateTime.of(2026, 8, 1, 9, 0)
        val firstDay = LocalDate.of(2026, 9, 7)
        val selection = WidgetSelector.select(
            now = now,
            occurrences = listOf(
                occurrence("第二节课", "10:00", "11:40", date = firstDay.plusDays(1)),
                occurrence("第一节课", "08:00", "09:40", date = firstDay)
            ),
            days = listOf(WidgetDay(now.toLocalDate(), null)),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("9月7日", selection.capsule)
        assertEquals(listOf("第一节课"), selection.occurrences.map { it.name })
        assertEquals("8月1日 周六", selection.title)
    }

    @Test
    fun `本学期课程已全部结束时显示已结束`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 30, 18, 0),
            occurrences = listOf(
                occurrence("最后一节", "14:00", "15:40", date = LocalDate.of(2026, 10, 30))
            ),
            days = emptyList(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.SEMESTER_ENDED, selection.mode)
        assertTrue(selection.occurrences.isEmpty())
        assertNull(selection.capsule)
    }

    @Test
    fun `尚未加载时显示加载提示模式`() {
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 8, 0),
            occurrences = listOf(occurrence("今天还有课", "10:00", "11:40")),
            days = teachingDays(),
            loaded = false
        )

        assertEquals(WidgetDisplayMode.NOT_LOADED, selection.mode)
        assertTrue(selection.occurrences.isEmpty())
        assertNull(selection.capsule)
        assertEquals("第 7 周 · 周四", selection.title)
    }

    @Test
    fun `下一节课缺少开始时刻时按当天节次取第一个`() {
        val saturday = LocalDate.of(2026, 10, 24)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 21, 0),
            occurrences = listOf(
                occurrence(
                    "缺钟点后",
                    null,
                    null,
                    startSection = 11,
                    endSection = 12,
                    date = saturday
                ),
                occurrence(
                    "缺钟点前",
                    null,
                    null,
                    startSection = 3,
                    endSection = 4,
                    date = saturday
                )
            ),
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.NEXT, selection.mode)
        assertEquals("周六", selection.capsule)
        assertEquals(listOf("缺钟点前"), selection.occurrences.map { it.name })
    }

    @Test
    fun `今天还有课次时优先显示今天的列表`() {
        val friday = thursday.plusDays(1)
        val selection = WidgetSelector.select(
            now = LocalDateTime.of(2026, 10, 22, 9, 0),
            occurrences = listOf(
                occurrence("今天稍后", "10:00", "11:40"),
                occurrence("明天的课", "08:00", "09:40", date = friday)
            ),
            days = teachingDays(),
            loaded = true
        )

        assertEquals(WidgetDisplayMode.TODAY, selection.mode)
        assertEquals(listOf("今天稍后"), selection.occurrences.map { it.name })
        assertNull(selection.capsule)
    }
}
