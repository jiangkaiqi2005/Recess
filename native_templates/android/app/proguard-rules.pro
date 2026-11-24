# WorkManager 2.7.1 经 home_widget 的 Glance 1.0 传递引入，内部用 Room 2.2.5 建库。
# 新版 R8 会剪掉这套旧 Room 的反射入口，导致启动时 WorkManager 初始化崩溃。
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-dontwarn androidx.room.paging.**