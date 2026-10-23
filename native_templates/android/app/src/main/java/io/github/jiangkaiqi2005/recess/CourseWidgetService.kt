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
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.time.LocalDateTime

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

        views.setTextViewText(R.id.widget_item_name, occurrence.name)
        views.setTextViewText(R.id.widget_item_time, WidgetText.timeLine(occurrence))
        // 地点始终占一行（没有地点时留空），保证色条在三条文字之间拉伸、
        // 且不同课次的行高一致。
        views.setTextViewText(R.id.widget_item_location, occurrence.location)
        views.setInt(
            R.id.widget_item_bar,
            "setBackgroundColor",
            widgetBarColor(context, occurrence)
        )
        // ListView 条目必须设置 fill-in Intent 才会响应 Provider 的点击模板；
        // 模板直接拉起 App、不读取条目位置，因此这里放空 Intent，不携带死数据。
        views.setOnClickFillInIntent(R.id.widget_item_root, Intent())
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    // 列表会随下课与刷新重排，position 并不稳定；返回它只为满足接口，
    // 配合 hasStableIds=false 让系统在数据变化时整表重建。
    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    private fun reload() {
        val data = WidgetData.load(context)
        val selection = WidgetSelector.select(
            now = LocalDateTime.now(),
            occurrences = data.occurrences,
            days = data.days,
            loaded = data.loaded
        )
        // 列表只负责今天的课次；下一节课兜底由 Provider 直接渲染，不进入列表。
        occurrences = if (selection.mode == WidgetDisplayMode.TODAY) {
            selection.occurrences
        } else {
            emptyList()
        }
    }
}
