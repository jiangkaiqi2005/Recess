package io.github.jiangkaiqi2005.recess

// Android 桌面小组件（App Widget）。读取 home_widget 共享的
// SharedPreferences 中由 Flutter 侧写入的课次数据，按当前本地时间挑选
// 今天还没结束的课次，交给 CourseWidgetService 填充 2×2 可滚动列表。
//
// 注意：此文件位于 native_templates/android/...，请复制到
// android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt
// （package 与真实 applicationId 一致，见 WIDGET_SETUP.md）。

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import java.time.LocalDateTime

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
        val data = WidgetData.load(context)
        val selection = WidgetSelector.select(
            now = LocalDateTime.now(),
            occurrences = data.occurrences,
            days = data.days
        )

        val views = RemoteViews(context.packageName, R.layout.course_widget)
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
        views.setOnClickPendingIntent(R.id.widget_root, launchAppIntent(context))

        val hasOccurrences = selection.occurrences.isNotEmpty()
        views.setViewVisibility(
            R.id.widget_list,
            if (hasOccurrences) View.VISIBLE else View.GONE
        )
        // 临时空文案：下一节课兜底与两种空状态由后续票实现。
        views.setViewVisibility(
            R.id.widget_empty,
            if (hasOccurrences) View.GONE else View.VISIBLE
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
        // RemoteViewsService 的列表有独立缓存，渲染后必须显式通知数据变化，
        // 否则改课、切学期后列表仍显示旧条目。
        appWidgetManager.notifyAppWidgetViewDataChanged(
            intArrayOf(appWidgetId),
            R.id.widget_list
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
