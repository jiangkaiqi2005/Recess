package io.github.jiangkaiqi2005.recess

// 上下课与零点自动刷新：每次渲染小组件后，用不精确闹钟安排下一次刷新。
//
// - 只使用 AlarmManager.setAndAllowWhileIdle + AlarmManager.RTC_WAKEUP，这是
//   非精确闹钟，不申请 SCHEDULE_EXACT_ALARM；RTC_WAKEUP 能在熄屏休眠时唤醒
//   设备触发刷新，Doze 下仍允许系统延后触发；
// - 始终使用同一个显式广播 PendingIntent 身份，安排前先 cancel，避免闹钟
//   越积越多；
// - 闹钟触发后回到 CourseWidgetProvider 重新渲染，渲染完成后再算一次
//   WidgetSelector.nextRefresh 并重新安排，形成自维持链；
// - course_widget_info.xml 的 30 分钟周期更新保留为兜底；不注册开机广播，
//   重启后由系统发出的 APPWIDGET_UPDATE 重新挂上闹钟。
//
// 注意：此文件位于 native_templates/android/...，请复制到
// android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRefreshScheduler.kt
// （package 与真实 applicationId 一致，见 WIDGET_SETUP.md）。

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.time.LocalDateTime
import java.time.ZoneId

/** 在下一次上课、下课或零点用不精确闹钟触发小组件更新。 */
internal object WidgetRefreshScheduler {

    /** 闹钟触发的显式广播 action；只发给 [CourseWidgetProvider]，不经过隐式广播。 */
    const val ACTION_REFRESH = "io.github.jiangkaiqi2005.recess.action.REFRESH_WIDGET"

    // 固定 requestCode + 固定 action：每次拿到的都是同一个 PendingIntent。
    private const val REQUEST_CODE = 4104

    // 调度延迟导致目标时刻已经过去时，安排一个很近的未来时刻，避免立即触发死循环。
    private const val MIN_DELAY_MILLIS = 10_000L

    fun schedule(context: Context, nextRefresh: LocalDateTime) {
        val appContext = context.applicationContext
        val alarmManager =
            appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pendingIntent = refreshPendingIntent(appContext)
        // 先取消之前挂的闹钟，再设置新的；同一个 PendingIntent 只会有一个待触发。
        alarmManager.cancel(pendingIntent)

        val triggerAtMillis = nextRefresh
            .atZone(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()
        val now = System.currentTimeMillis()
        val safeTriggerAtMillis =
            if (triggerAtMillis > now) triggerAtMillis else now + MIN_DELAY_MILLIS
        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            safeTriggerAtMillis,
            pendingIntent
        )
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, CourseWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
