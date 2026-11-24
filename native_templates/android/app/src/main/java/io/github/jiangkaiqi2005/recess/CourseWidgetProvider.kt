package io.github.jiangkaiqi2005.recess

// Android 桌面小组件（App Widget）。读取 home_widget 共享的
// SharedPreferences 中由 Flutter 侧写入的课次数据，按当前本地时间挑选
// 今天还没结束的课次；今天没有剩余课次时改为显示一条带日期胶囊的
// 下一节课，两种空状态分别提示加载课表与学期结束。每次渲染后用不精确
// 闹钟安排下一次上课、下课或零点的刷新。
//
// 注意：此文件位于 native_templates/android/...，请复制到
// android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt
// （package 与真实 applicationId 一致，见 WIDGET_SETUP.md）。

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import java.time.LocalDateTime

open class CourseWidgetProvider : AppWidgetProvider() {

    protected open val layoutId = R.layout.course_widget

    companion object {
        // 闹钟统一发给原有 Receiver，再按各自布局刷新所有尺寸。
        private fun providers() = listOf(
            CourseWidgetProvider(),
            CourseWidget3x2Provider(),
            CourseWidget2x3Provider(),
            CourseWidget4x2Provider(),
            CourseWidget4x4Provider()
        )
    }

    /**
     * 不精确闹钟到点后用显式广播回到这里，对全部小组件重走 [onUpdate]；
     * 渲染结束后会重新计算并安排下一次闹钟，形成自维持链。
     * 不注册开机广播：重启后系统照常发出 APPWIDGET_UPDATE，onUpdate 重新挂上闹钟。
     */
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == WidgetRefreshScheduler.ACTION_REFRESH) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            for (provider in providers()) {
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, provider.javaClass)
                )
                if (appWidgetIds.isNotEmpty()) {
                    provider.onUpdate(context, appWidgetManager, appWidgetIds)
                }
            }
            return
        }
        super.onReceive(context, intent)
    }

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
        val data = WidgetData.load(context)
        val selection = WidgetSelector.select(
            now = LocalDateTime.now(),
            occurrences = data.occurrences,
            days = data.days,
            loaded = data.loaded
        )

        val views = RemoteViews(context.packageName, layoutId)
        views.setTextViewText(R.id.widget_title, selection.title)
        views.setRemoteAdapter(
            appWidgetId,
            R.id.widget_list,
            Intent(context, CourseWidgetService::class.java)
        )
        // 条目本身只带 fill-in Intent，点击模板负责拉起 App 的课表页。
        // 模板是不可变 PendingIntent，系统会忽略 fill-in Intent 的附加数据，
        // 但条目点击依然会执行模板；这一票不需要深链，所以不改用 FLAG_MUTABLE。
        views.setPendingIntentTemplate(R.id.widget_list, launchAppIntent(context))
        // 根布局、兜底条目与空状态点击都拉起 App 的课表页。
        val launchIntent = launchAppIntent(context)
        views.setOnClickPendingIntent(android.R.id.background, launchIntent)
        views.setOnClickPendingIntent(R.id.widget_item_root, launchIntent)
        views.setOnClickPendingIntent(R.id.widget_empty, launchIntent)

        when (selection.mode) {
            WidgetDisplayMode.TODAY -> {
                views.setViewVisibility(R.id.widget_list, View.VISIBLE)
                views.setViewVisibility(R.id.widget_fallback, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
            }

            WidgetDisplayMode.NEXT -> {
                views.setViewVisibility(R.id.widget_list, View.GONE)
                views.setViewVisibility(R.id.widget_fallback, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                renderNextOccurrence(context, views, selection)
            }

            WidgetDisplayMode.SEMESTER_ENDED,
            WidgetDisplayMode.NOT_LOADED -> {
                views.setViewVisibility(R.id.widget_list, View.GONE)
                views.setViewVisibility(R.id.widget_fallback, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty,
                    if (selection.mode == WidgetDisplayMode.SEMESTER_ENDED) {
                        "本学期课程已结束"
                    } else {
                        "打开 Recess 加载课表"
                    }
                )
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
        // RemoteViewsService 的列表有独立缓存，渲染后必须显式通知数据变化，
        // 否则改课、切学期后列表仍显示旧条目。
        appWidgetManager.notifyAppWidgetViewDataChanged(
            intArrayOf(appWidgetId),
            R.id.widget_list
        )
        // 每次渲染后安排下一次上下课/零点刷新；上面已显式通知数据变化，
        // 闹钟触发时 onReceive 会重新渲染并再次安排，不会越积越多。
        WidgetRefreshScheduler.schedule(context, selection.nextRefresh)
    }

    /** 兜底条目与列表条目同构：色条 + 课程名 / 时间段 / 地点，不能滚动。 */
    private fun renderNextOccurrence(
        context: Context,
        views: RemoteViews,
        selection: WidgetSelection
    ) {
        val occurrence = selection.occurrences.first()
        views.setTextViewText(R.id.widget_capsule, selection.capsule.orEmpty())
        views.setTextViewText(R.id.widget_item_name, occurrence.name)
        views.setTextViewText(R.id.widget_item_time, WidgetText.timeLine(occurrence))
        views.setTextViewText(R.id.widget_item_location, occurrence.location)
        views.setInt(
            R.id.widget_item_bar,
            "setBackgroundColor",
            widgetBarColor(context, occurrence)
        )
    }

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
}
