package io.github.jiangkaiqi2005.recess

// 小组件文字格式化。
//
// Provider（下一节课兜底）与 RemoteViewsService（今天列表）共用这一份格式，
// 避免两处各写一遍时间行。周次、节次时间与钟点取舍都由 Dart 侧算好并写入
// 课次数据，这里只把已有字段拼成显示文字，不重算课表规则。

import java.time.LocalDateTime
import java.util.Locale

/** 纯 Kotlin 的课次文字格式化，可被 JVM 单测直接覆盖。 */
object WidgetText {

    /** 完整起止时刻写「08:00-09:40」；缺少任意一端时写「第 11-12 节」。 */
    fun timeLine(occurrence: WidgetOccurrence): String {
        val start = occurrence.start
        val end = occurrence.end
        return if (start != null && end != null) {
            "${clock(start)}-${clock(end)}"
        } else {
            "第 ${occurrence.startSection}-${occurrence.endSection} 节"
        }
    }

    private fun clock(time: LocalDateTime): String =
        String.format(Locale.ROOT, "%02d:%02d", time.hour, time.minute)
}
