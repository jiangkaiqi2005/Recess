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
| `native_templates/android/build.gradle` | `android/build.gradle`（把 `__NDK_VERSION__` 替换为本机 NDK 版本；CI 自动替换） |
| `native_templates/android/settings.gradle` | `android/settings.gradle` |
| `native_templates/android/gradle/wrapper/gradle-wrapper.properties` | `android/gradle/wrapper/gradle-wrapper.properties` |
| `native_templates/android/app/build.gradle.kts` | `android/app/build.gradle.kts` |
| `native_templates/android/app/src/main/AndroidManifest.xml` | `android/app/src/main/AndroidManifest.xml` |
| `native_templates/android/app/src/main/kotlin/io/github/jiangkaiqi2005/recess/MainActivity.kt` | `android/app/src/main/kotlin/io/github/jiangkaiqi2005/recess/MainActivity.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetProvider.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetSizeProviders.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetSizeProviders.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetService.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/CourseWidgetService.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetData.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetData.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetSelector.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetSelector.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRefreshScheduler.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRefreshScheduler.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetText.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetText.kt` |
| `native_templates/android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRender.kt` | `android/app/src/main/java/io/github/jiangkaiqi2005/recess/WidgetRender.kt` |
| `native_templates/android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetSelectorTest.kt` | `android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetSelectorTest.kt` |
| `native_templates/android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetTextTest.kt` | `android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetTextTest.kt` |
| `native_templates/android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetDataTest.kt` | `android/app/src/test/java/io/github/jiangkaiqi2005/recess/WidgetDataTest.kt` |
| `native_templates/android/app/src/main/res/xml/course_widget_info.xml` | `android/app/src/main/res/xml/course_widget_info.xml` |
| `native_templates/android/app/src/main/res/xml/course_widget_{3x2,2x3,4x2,4x4}_info.xml` | `android/app/src/main/res/xml/`（四份尺寸配置，文件名不变） |
| `native_templates/android/app/src/main/res/layout/course_widget.xml` | `android/app/src/main/res/layout/course_widget.xml` |
| `native_templates/android/app/src/main/res/layout/course_widget_{3x2,2x3,4x2,4x4}.xml` | `android/app/src/main/res/layout/`（四份外层布局，文件名不变） |
| `native_templates/android/app/src/main/res/layout/course_widget_content.xml` | `android/app/src/main/res/layout/course_widget_content.xml`（所有尺寸共用内容） |
| `native_templates/android/app/src/main/res/layout/course_widget_item.xml` | `android/app/src/main/res/layout/course_widget_item.xml` |
| `native_templates/android/app/src/main/res/drawable/course_widget_background.xml` | `android/app/src/main/res/drawable/course_widget_background.xml` |
| `native_templates/android/app/src/main/res/drawable/course_widget_capsule.xml` | `android/app/src/main/res/drawable/course_widget_capsule.xml` |
| `native_templates/android/app/src/main/res/drawable/course_widget_square.xml` | `android/app/src/main/res/drawable/course_widget_square.xml`（2×2、4×4 共用） |
| `native_templates/android/app/src/main/res/drawable/course_widget_ratio_{3x2,2x3,4x2}.xml` | `android/app/src/main/res/drawable/`（三份透明比例垫片，文件名不变） |
| `native_templates/android/app/src/main/res/values/colors.xml` | `android/app/src/main/res/values/colors.xml` |
| `native_templates/android/app/src/main/res/values-night/colors.xml` | `android/app/src/main/res/values-night/colors.xml` |
| `native_templates/android/app/src/main/res/xml/filepaths.xml` | `android/app/src/main/res/xml/filepaths.xml` |

模板中的 Kotlin 包名与真实包名 `io.github.jiangkaiqi2005.recess` 一致，复制后无需修改。

也可以在 Git Bash 中一次性覆盖复制整个原生模板：

```bash
cp native_templates/android/settings.gradle android/settings.gradle
cp native_templates/android/gradle/wrapper/gradle-wrapper.properties android/gradle/wrapper/gradle-wrapper.properties
cp native_templates/android/app/build.gradle.kts android/app/build.gradle.kts
mkdir -p android/app/src/test
cp -R native_templates/android/app/src/main/. android/app/src/main/
cp -R native_templates/android/app/src/test/. android/app/src/test/
: "${ANDROID_HOME:?请先设置 ANDROID_HOME 指向 Android SDK}"
NDK_VERSION=$(ls "$ANDROID_HOME/ndk" | sort -V | tail -1)
: "${NDK_VERSION:?未在 $ANDROID_HOME/ndk 找到 NDK，请先用 sdkmanager 安装}"
sed "s/__NDK_VERSION__/$NDK_VERSION/g" native_templates/android/build.gradle > android/build.gradle
```

根目录 `build.gradle` 含 `__NDK_VERSION__` 占位符，不能直接复制；上面的
`sed` 从 `$ANDROID_HOME/ndk` 取版本号排序后的最新一个填入，也可以手工替换。
`ANDROID_HOME` 未设置或该目录下没有 NDK 时，上面的命令会直接报错退出，
不会生成空 `ndkVersion` 的 `build.gradle`。

Gradle 模板包含 API 24 最低版本、通知等依赖所需的 desugaring 版本、架构过滤和固定签名配置。
若旧的本地工程仍有 `android/app/build.gradle`，请先备份并合并其中的自定义配置，
最终只保留一种 app 模块构建脚本，避免 Groovy 文件优先于 Kotlin 模板。

上表的 `{3x2,2x3,4x2,4x4}` 表示分别复制这些尺寸的文件。完整的
`AndroidManifest.xml` 已注册五个桌面小组件 Receiver、供列表使用的
RemoteViewsService（`BIND_REMOTEVIEWS` 权限，`exported="false"`）与应用内更新所需的
FileProvider/安装权限；`AndroidManifest.receiver.xml` 仅作为 Receiver 片段参考。

Android 上 `home_widget` 将数据写入 `HomeWidgetPreferences`（`home_widget 0.6.0`
的 `HomeWidgetPlugin.PREFERENCES`；升级插件时需核对）；
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

`WidgetSelector` 同时算出下一次需要刷新的时刻（今天剩余课次中最近的上课或
下课时刻，与下一个零点取较早者）。`CourseWidgetProvider` 每次渲染后调用
`WidgetRefreshScheduler`，用不精确闹钟在该时刻触发一次显式广播，回到
`onReceive`，按五个 Provider 的 `ComponentName` 查询实例，用各自布局重新渲染。
所有尺寸使用同一个发给 `CourseWidgetProvider` 的 PendingIntent，仍只有一条闹钟链；
即使桌面只剩新尺寸，闹钟也会刷新它们。Flutter 写入数据后也逐一通知五个 Provider，
某个尺寸通知失败不会阻止其他尺寸。

五种尺寸的列表、下一节课和两种空状态完全相同，不分栏。旧的 2×2 仍叫「今日课程」，
新增项分别叫「今日课程 3×2」「今日课程 2×3」「今日课程 4×2」「今日课程 4×4」。
每项都设 `resizeMode="none"`、对应的 `targetCellWidth/Height` 和 30 分钟周期更新。

| 尺寸 | minWidth | minHeight | 卡片比例 | 透明垫片固有尺寸 |
|---|---|---|---|---|
| 2×2 | 110dp | 110dp | 1:1 | 1000×1000dp |
| 3×2 | 190dp | 110dp | 3:2 | 1500×1000dp |
| 2×3 | 110dp | 220dp | 2:3 | 1000×1500dp |
| 4×2 | 270dp | 110dp | 2:1 | 2000×1000dp |
| 4×4 | 270dp | 310dp | 1:1 | 1000×1000dp |

最小宽高依据 Xiaomi 14（HyperOS 3.0、Android 16）已有的 4 列桌面实测选择：
横向格距约 81.5dp、纵向约 93dp，原有 110dp 对应 2 格。保留 2 格的 110dp，
3、4 列分别选在横向 2～3、3～4 格距之间的 190dp、270dp；
3、4 行分别选在纵向 2～3、3～4 格距之间的 220dp、310dp，避开格数边界。
这是基于现有测量的配置选择，新尺寸仍需真机验收。HyperOS 可能忽略 targetCell，
5 列桌面不校准占格；卡片仍由透明 shape 与 `adjustViewBounds` 按固定比例居中，
不在代码里计算尺寸。不添加 `miuiWidget` 等审核标识。

## 3. 验证

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter run
```

打开课表主页后返回系统桌面，分别添加五种尺寸。检查 4 列桌面的标称占格、
卡片居中和比例、深浅色、今日列表、下一节课、两种空状态与点击行为；
5 列桌面允许占格变化，但卡片仍应按比例居中。检查同时放多个尺寸以及只留新尺寸时，
修改课程、跨上下课、零点和重启都能恢复刷新。真机验收需记录机型、系统和桌面列数。

复制模板后还可以运行挑选类的 JVM 单测（CI 不生成 `android/`，因此不覆盖这部分）：

```bash
cd android
./gradlew :app:testDebugUnitTest
```

Windows 下如 `gradlew` 不可执行，可用 `cmd //c gradlew.bat :app:testDebugUnitTest`。

## 4. 已知限制

- App 不在前台时不会重新计算课表；跨天、上课和下课后的更新由原生端的不精确
  闹钟触发。`WidgetSelector` 算出的下一次刷新时刻交给
  `WidgetRefreshScheduler`，每次安排前先取消旧闹钟；到点后重新渲染并重新
  安排，形成自维持链。App 仍在课表、节次、学期变化或回到前台时主动写入并刷新。
- 不申请 `SCHEDULE_EXACT_ALARM`，也不使用 `setExact*`。闹钟使用
  `AlarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, ...)`，能在熄屏
  休眠时唤醒设备触发刷新；Doze 或省电策略下仍可能延迟几分钟才更新。
- 保留五份小组件配置的 `updatePeriodMillis="1800000"`（30 分钟）
  系统周期更新作为兜底；若系统限制后台广播，最坏情况下要等下一次 30 分钟更新。
- 不注册开机广播（`BOOT_COMPLETED`）。手机重启后，系统发出的
  `APPWIDGET_UPDATE` 会让 `CourseWidgetProvider.onUpdate` 重新挂上闹钟，
  不需要打开 App。
- 小组件有固定 2×2、3×2、2×3、4×2、4×4 五项可滚动课次列表
  （`CourseWidgetService` 提供条目），不能拉伸；卡片由透明垫片按各自比例撑开，
  在格子里居中。今天没有剩余课次时
  改为一条不可滚动的下一节课，上方用
  主题色胶囊标注日期；从未加载时显示「打开 Recess 加载课表」，本学期剩余
  时间没有课次时显示「本学期课程已结束」。
- `native_templates/android/app/src/test/` 下的 Kotlin 单测只在本地复制模板后
  用 Gradle 运行，CI 不执行。
- ICS 时间按学校本地时间处理，忽略 `TZID`/UTC 偏移。
