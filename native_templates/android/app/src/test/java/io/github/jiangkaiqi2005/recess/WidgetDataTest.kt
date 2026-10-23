package io.github.jiangkaiqi2005.recess

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * 固定 home_widget 的偏好表名称。
 *
 * 名称写错时真机上永远读不到数据，而 JVM 单测无法从插件侧反查；这里至少
 * 防止有人改回旧名称。升级 home_widget 时须对照 HomeWidgetPlugin.PREFERENCES
 * 更新实现与这个断言。
 */
class WidgetDataTest {

    @Test
    fun `home_widget 0_6_0 使用 HomeWidgetPreferences 偏好表`() {
        assertEquals("HomeWidgetPreferences", WidgetData.PREFS_NAME)
    }
}
