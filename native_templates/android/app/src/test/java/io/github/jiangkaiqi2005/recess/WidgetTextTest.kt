package io.github.jiangkaiqi2005.recess

import java.time.LocalDate
import java.time.LocalDateTime
import org.junit.Assert.assertEquals
import org.junit.Test

/** [WidgetText] 的 JVM 单测：Provider 与 RemoteViewsService 共用的时间行格式。 */
class WidgetTextTest {

    private val date = LocalDate.of(2026, 10, 22)

    private fun occurrence(
        start: String?,
        end: String?,
        startSection: Int = 11,
        endSection: Int = 12
    ) = WidgetOccurrence(
        date = date,
        start = start?.let { LocalDateTime.parse("${date}T$it") },
        end = end?.let { LocalDateTime.parse("${date}T$it") },
        startSection = startSection,
        endSection = endSection,
        name = "高等数学",
        location = "",
        colorLight = 0xFF4399F1.toInt(),
        colorDark = 0xFF217BD1.toInt()
    )

    @Test
    fun `完整起止时刻写成起止时间`() {
        assertEquals("08:00-09:40", WidgetText.timeLine(occurrence("08:00", "09:40")))
    }

    @Test
    fun `缺少任意一端钟点时写成节次`() {
        assertEquals("第 11-12 节", WidgetText.timeLine(occurrence(null, null)))
        assertEquals("第 11-12 节", WidgetText.timeLine(occurrence("08:00", null)))
        assertEquals("第 11-12 节", WidgetText.timeLine(occurrence(null, "09:40")))
    }
}
