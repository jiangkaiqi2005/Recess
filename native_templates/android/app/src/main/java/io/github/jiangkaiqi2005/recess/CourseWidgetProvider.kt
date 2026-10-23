package io.github.jiangkaiqi2005.recess

// Android 桌面小组件（App Widget）。读取 home_widget 共享的
// SharedPreferences 中由 Flutter 侧写入的课次数据，按当前本地时间挑选
// 今天还没结束的课次，并用现有纯文本布局显示。
//
// 注意：此文件位于 native_templates/android/...，请复制到
// android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt
// （package 与真实 applicationId 一致，见 WIDGET_SETUP.md）。

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.Locale
import org.json.JSONArray

class CourseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // home_widget 在 Android 上将数据写入名为 HomeWidgetSharedPreferences 的偏好表。
        val prefs = context.getSharedPreferences(
            "HomeWidgetSharedPreferences",
            Context.MODE_PRIVATE
        )
        val occurrences = parseOccurrences(prefs.getString(KEY_OCCURRENCES, null))
        val days = parseDays(prefs.getString(KEY_SEMESTER_DAYS, null))
        // `widget_loaded` 用于区分「从未加载」与「已加载但没有课次」，
        // 空状态文案在后续票中处理，这里暂不渲染。
        val selection = WidgetSelector.select(
            now = LocalDateTime.now(),
            occurrences = occurrences,
            days = days
        )

        val content = if (selection.occurrences.isEmpty()) {
            "今天没有课 🎉"
        } else {
            selection.occurrences.joinToString("\n") { lineFor(it) }
        }

        val views = RemoteViews(context.packageName, R.layout.course_widget)
        views.setTextViewText(R.id.widget_title, selection.title)
        views.setTextViewText(R.id.widget_courses, content)
        views.setOnClickPendingIntent(R.id.widget_root, launchAppIntent(context))
        appWidgetManager.updateAppWidget(appWidgetId, views)
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

    private fun lineFor(occurrence: WidgetOccurrence): String {
        val time = if (occurrence.start != null && occurrence.end != null) {
            "${formatTime(occurrence.start)}-${formatTime(occurrence.end)}"
        } else {
            "第${occurrence.startSection}-${occurrence.endSection}节"
        }
        return buildString {
            append(time)
            append("  ")
            append(occurrence.name)
            if (occurrence.location.isNotEmpty()) append("  @${occurrence.location}")
        }
    }

    private fun formatTime(time: LocalDateTime): String =
        String.format(Locale.ROOT, "%02d:%02d", time.hour, time.minute)

    /** 点击小组件任意位置打开 App 的课表页（普通启动，不使用深链）。 */
    private fun launchAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private companion object {
        const val KEY_OCCURRENCES = "occurrences"
        const val KEY_SEMESTER_DAYS = "semester_days"
    }
}
