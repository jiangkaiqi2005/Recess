# Android 桌面小组件整合指南

Flutter 侧的 `lib/features/widget/` 会预先算出本学期剩余的全部课次，写入
`home_widget` 的数据通道，并触发 Android App Widget 刷新。

原生小组件代码保存在 `native_templates/android/`。由于生成的 `android/`
目录不提交到仓库，首次克隆后需要按下面步骤恢复并接入模板。

## 1. 生成 Android 工程

在仓库根目录执行：

```bash
flutter create . --platforms=android --org io.github.jiangkaiqi2005
flutter pub get
```

## 2. 复制 Android 原生模板

| 模板文件 | 目标位置 |
|---|---|
| `native_templates/android/app/build.gradle.kts` | `android/app/build.gradle.kts` |
| `native_templates/android/app/src/main/AndroidManifest.xml` | `android/app/src/main/AndroidManifest.xml` |
| `native_templates/android/app/src/main/kotlin/io/github/jiangkaiqi2005/recess/MainActivity.kt` | `android/app/src/main/kotlin/io/github/jiangkaiqi2005/recess/MainActivity.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetService.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetService.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetData.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetData.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetSelector.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetSelector.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetText.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetText.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRender.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRender.kt` |
| `native_templates/android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetSelectorTest.kt` | `android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetSelectorTest.kt` |
| `native_templates/android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetTextTest.kt` | `android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetTextTest.kt` |
| `native_templates/android/app/src/main/res/xml/course_widget_info.xml` | `android/app/src/main/res/xml/course_widget_info.xml` |
| `native_templates/android/app/src/main/res/layout/course_widget.xml` | `android/app/src/main/res/layout/course_widget.xml` |
| `native_templates/android/app/src/main/res/layout/course_widget_item.xml` | `android/app/src/main/res/layout/course_widget_item.xml` |
| `native_templates/android/app/src/main/res/drawable/course_widget_background.xml` | `android/app/src/main/res/drawable/course_widget_background.xml` |
| `native_templates/android/app/src/main/res/drawable/course_widget_capsule.xml` | `android/app/src/main/res/drawable/course_widget_capsule.xml` |
| `native_templates/android/app/src/main/res/values/colors.xml` | `android/app/src/main/res/values/colors.xml` |
| `native_templates/android/app/src/main/res/values-night/colors.xml` | `android/app/src/main/res/values-night/colors.xml` |
| `native_templates/android/app/src/main/res/xml/filepaths.xml` | `android/app/src/main/res/xml/filepaths.xml` |

模板中的 Kotlin 包名与真实包名 `io.github.jiangkaiqi2005.recess` 一致，复制后无需修改。

也可以在 PowerShell 中一次性覆盖复制整个原生模板：

```powershell
Copy-Item native_templates/android/app/build.gradle.kts android/app/build.gradle.kts -Force
Copy-Item native_templates/android/app/src/main/* android/app/src/main/ -Recurse -Force
Copy-Item native_templates/android/app/src/test android/app/src/ -Recurse -Force
```

Gradle 模板包含 API 24 最低版本、通知等依赖所需的 desugaring 版本、架构过滤和固定签名配置。
若旧的本地工程仍有 `android/app/build.gradle`，请先备份并合并其中的自定义配置，
最终只保留一种 app 模块构建脚本，避免 Groovy 文件优先于 Kotlin 模板。

完整的 `AndroidManifest.xml` 已注册桌面小组件 Receiver、供列表使用的
RemoteViewsService（`BIND_REMOTEVIEWS` 权限，`exported="false"`）与应用内更新所需的
FileProvider/安装权限；`AndroidManifest.receiver.xml` 仅作为 Receiver 片段参考。

Android 上 `home_widget` 将数据写入 `HomeWidgetSharedPreferences`；
`CourseWidgetProvider` 与 `CourseWidgetService` 通过 `WidgetData` 读取其中的
`occurrences`（从今天到学期结束的课次列表）、`semester_days`（逐日教学周映射）
与 `widget_loaded`（是否成功写入过数据）。周次、钟点都由 Dart 侧算好，原生端的
`WidgetSelector` 只按当前本地时间挑选：今天还有剩余课次时显示列表；今天没有
剩余课次时显示一条下一节课，并用主题色胶囊标注「明天 · 周五」「周六」
「下周一」或「11月3日」；`widget_loaded` 为 false 时提示加载课表，已加载但
剩余时间没有课次时提示学期结束。`CourseWidgetService` 把今天的课次填充到
小组件里的 `ListView`，`CourseWidgetProvider` 直接渲染不能滚动的兜底条目；
条目颜色取自 Dart 写入的 `color` / `color_dark`（`WidgetRender` 与
`WidgetText` 为两处共用的颜色与时间行格式），表面色、文字色与胶囊色见
`values/colors.xml` 与 `values-night/colors.xml`。

## 3. 验证

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter run
```

打开课表主页后返回系统桌面，添加“今日课程”小组件。小组件应显示当天课程；
点击后应能拉起 App。

复制模板后还可以运行挑选类的 JVM 单测（CI 不生成 `android/`，因此不覆盖这部分）：

```bash
cd android
./gradlew :app:testDebugUnitTest
```

Windows 下如 `gradlew` 不可执行，可用 `cmd //c gradlew.bat :app:testDebugUnitTest`。

## 4. 已知限制

- 小组件刷新集中由应用根部的 `_AppEffects` 驱动：监听学期/课程/节次变化（防抖）
  与回到前台、跨过午夜时补刷；App 未在后台运行时不刷新。原生侧尚未在
  上下课时刻自行安排刷新（后续票处理）。
- 尚未接入 Android 后台定时任务（如需整点自定义，可加 `WorkManager` 或
  `home_widget` 的 background callback）。
- 小组件为 2×2 的可滚动课次列表（`CourseWidgetService` 提供条目），可以拉伸、
  不能缩到 2×2 以下；今天没有剩余课次时改为一条不可滚动的下一节课，上方用
  主题色胶囊标注日期；从未加载时显示「打开 Recess 加载课表」，本学期剩余
  时间没有课次时显示「本学期课程已结束」。
- `native_templates/android/app/src/test/` 下的 Kotlin 单测只在本地复制模板后
  用 Gradle 运行，CI 不执行。
- ICS 时间按学校本地时间处理，忽略 `TZID`/UTC 偏移。
