package io.github.jiangkaiqi2005.recess

// 读取 home_widget 写入 SharedPreferences 的课次、逐日教学周与加载标记。
//
// Provider 与 RemoteViewsService 共用这一份解析，避免两处各写一遍 JSON；
// 这里只做格式解析，挑选逻辑仍然只在纯 Kotlin 的 WidgetSelector 里。
//
// 注意：此文件位于 native_templates/android/...，请复制到
// android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetData.kt
// （package 与真实 applicationId 一致，见 WIDGET_SETUP.md）。

import android.content.Context
import java.time.LocalDate
import java.time.LocalDateTime
import org.json.JSONArray

/**
 * 一次读取得到的原生侧数据快照。
 *
 * [loaded] 对应 Dart 侧写入的 `widget_loaded`：缺失或为 false 表示从未成功
 * 写入过数据，用来区分「尚未加载」与「已加载但本学期没有课次」。
 */
internal data class WidgetData(
    val occurrences: List<WidgetOccurrence>,
    val days: List<WidgetDay>,
    val loaded: Boolean
) {
    companion object {
        // 名称必须与 home_widget 0.6.0 的 HomeWidgetPlugin.PREFERENCES 一致
        // （android/src/main/kotlin/es/antonborri/home_widget/HomeWidgetPlugin.kt），
        // 否则读不到 Dart 写入的数据，小组件会一直显示「打开 Recess 加载课表」。
        // 升级 home_widget 时先核对插件的这个常量；WidgetDataTest 会盯住该值。
        internal const val PREFS_NAME = "HomeWidgetPreferences"
        private const val KEY_OCCURRENCES = "occurrences"
        private const val KEY_SEMESTER_DAYS = "semester_days"
        private const val KEY_LOADED = "widget_loaded"

        fun load(context: Context): WidgetData {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return WidgetData(
                occurrences = parseOccurrences(prefs.getString(KEY_OCCURRENCES, null)),
                days = parseDays(prefs.getString(KEY_SEMESTER_DAYS, null)),
                loaded = prefs.getBoolean(KEY_LOADED, false)
            )
        }

        private fun parseOccurrences(raw: String?): List<WidgetOccurrence> {
            if (raw.isNullOrEmpty()) return emptyList()
            return try {
                val array = JSONArray(raw)
                buildList {
                    for (index in 0 until array.length()) {
                        val item = array.getJSONObject(index)
                        add(
                            WidgetOccurrence(
                                date = LocalDate.parse(item.getString("date")),
                                start = parseMoment(item.optString("start", "")),
                                end = parseMoment(item.optString("end", "")),
                                startSection = item.optInt("start_section", 0),
                                endSection = item.optInt("end_section", 0),
                                name = item.optString("name", ""),
                                location = item.optString("location", ""),
                                colorLight = item.optLong("color", 0L).toInt(),
                                colorDark = item.optLong("color_dark", 0L).toInt()
                            )
                        )
                    }
                }
            } catch (_: Exception) {
                // 解析失败按没有数据展示，等下一次 App 刷新重写。
                emptyList()
            }
        }

        private fun parseDays(raw: String?): List<WidgetDay> {
            if (raw.isNullOrEmpty()) return emptyList()
            return try {
                val array = JSONArray(raw)
                buildList {
                    for (index in 0 until array.length()) {
                        val item = array.getJSONObject(index)
                        val week = item.optInt("week", 0)
                        add(
                            WidgetDay(
                                date = LocalDate.parse(item.getString("date")),
                                week = week.takeIf { it > 0 }
                            )
                        )
                    }
                }
            } catch (_: Exception) {
                emptyList()
            }
        }

        private fun parseMoment(value: String): LocalDateTime? {
            if (value.isEmpty()) return null
            return try {
                LocalDateTime.parse(value)
            } catch (_: Exception) {
                null
            }
        }
    }
}
