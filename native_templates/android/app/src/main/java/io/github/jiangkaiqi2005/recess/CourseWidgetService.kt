package io.github.jiangkaiqi2005.recess

// 桌面小组件里「今天剩余课次」列表的数据源。
//
// 每次系统要求刷新数据时重新读取 home_widget 写入的 SharedPreferences，
// 并用纯 Kotlin 的 WidgetSelector 挑出今天还没结束的课次，保证挑选逻辑
// 与 Provider 只有一份。列表条目的深浅色由系统 uiMode 与 Dart 写入的
// color / color_dark 决定，不在原生端做色板映射。
//
// 注意：此文件位于 native_templates/android/...，请复制到
// android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetService.kt
// （package 与真实 applicationId 一致，见 WIDGET_SETUP.md）。

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.time.LocalDateTime
import java.util.Locale

/** 供小组件 ListView 使用的 RemoteViewsService。 */
class CourseWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        CourseWidgetFactory(applicationContext)
}

/**
 * 列表条目工厂。
 *
 * 数据来自 [WidgetData] + [WidgetSelector]，渲染只用到 RemoteViews 支持的
 * 方法（setTextViewText / setInt(setBackgroundColor) / setOnClickFillInIntent）。
 */
private class CourseWidgetFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    private var occurrences: List<WidgetOccurrence> = emptyList()

    override fun onCreate() {
        // 数据加载统一放在 onDataSetChanged（系统保证在首次 getViewAt 之前调用），
        // 避免在主线程的 onCreate 里读 SharedPreferences。
    }

    override fun onDataSetChanged() {
        // 列表有独立缓存，Provider 触发数据变化后会走到这里重新读数据。
        reload()
    }

    override fun onDestroy() {
    }

    override fun getCount(): Int = occurrences.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.course_widget_item)
        val occurrence = occurrences.getOrNull(position) ?: return views
        val night = isNightMode()

        views.setTextViewText(R.id.widget_item_name, occurrence.name)
        views.setTextViewText(R.id.widget_item_time, timeLine(occurrence))
        // 地点始终占一行（没有地点时留空），保证色条在三条文字之间拉伸、
        // 且不同课次的行高一致。
        views.setTextViewText(R.id.widget_item_location, occurrence.location)
        views.setInt(
            R.id.widget_item_bar,
            "setBackgroundColor",
            if (night) occurrence.colorDark else occurrence.colorLight
        )
        // 条目只提供 fill-in Intent，真正的启动动作来自 Provider 设置的点击模板。
        views.setOnClickFillInIntent(
            R.id.widget_item_root,
            Intent().putExtra(EXTRA_POSITION, position)
        )
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    private fun reload() {
        val data = WidgetData.load(context)
        occurrences = WidgetSelector.select(
            now = LocalDateTime.now(),
            occurrences = data.occurrences,
            days = data.days
        ).occurrences
    }

    private fun isNightMode(): Boolean {
        val uiMode = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK
        return uiMode == Configuration.UI_MODE_NIGHT_YES
    }

    /** 完整起止时刻写「08:00-09:40」；缺少任意一端时写「第 11-12 节」。 */
    private fun timeLine(occurrence: WidgetOccurrence): String {
        val start = occurrence.start
        val end = occurrence.end
        return if (start != null && end != null) {
            "${formatClock(start)}-${formatClock(end)}"
        } else {
            "第 ${occurrence.startSection}-${occurrence.endSection} 节"
        }
    }

    private fun formatClock(time: LocalDateTime): String =
        String.format(Locale.ROOT, "%02d:%02d", time.hour, time.minute)

    private companion object {
        const val EXTRA_POSITION = "widget_item_position"
    }
}
