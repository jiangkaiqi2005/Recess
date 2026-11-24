package io.github.jiangkaiqi2005.recess

// 各尺寸共享课次与刷新逻辑，只替换保持比例的外层布局。
class CourseWidget3x2Provider : CourseWidgetProvider() {
    override val layoutId = R.layout.course_widget_3x2
}

class CourseWidget2x3Provider : CourseWidgetProvider() {
    override val layoutId = R.layout.course_widget_2x3
}

class CourseWidget4x2Provider : CourseWidgetProvider() {
    override val layoutId = R.layout.course_widget_4x2
}

class CourseWidget4x4Provider : CourseWidgetProvider() {
    override val layoutId = R.layout.course_widget_4x4
}
