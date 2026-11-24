package io.github.jiangkaiqi2005.recess

// 小组件渲染共用的颜色选择。
//
// 表面色、文字色与胶囊色直接由 values / values-night 资源切换；
// 只有课程色条需要从 Dart 写入的两个色值里按系统深浅色挑一个。
// Provider（兜底条目）与 RemoteViewsService（列表条目）共用这份逻辑。

import android.content.Context
import android.content.res.Configuration

/** 课程色条颜色：浅色用 [WidgetOccurrence.colorLight]，深色用 [WidgetOccurrence.colorDark]。 */
internal fun widgetBarColor(context: Context, occurrence: WidgetOccurrence): Int {
    val uiMode = context.resources.configuration.uiMode and
        Configuration.UI_MODE_NIGHT_MASK
    return if (uiMode == Configuration.UI_MODE_NIGHT_YES) {
        occurrence.colorDark
    } else {
        occurrence.colorLight
    }
}
