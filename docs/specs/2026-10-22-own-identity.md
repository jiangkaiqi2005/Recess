# 去掉原作者标识，改为 jiangkaiqi2005 自有身份

## 背景与已确认决定

这个仓库 fork 自 Aetik-yue/hormone，已经改名为 Recess（提交 89845fb），但里面还留着原作者的身份：

- 安卓包名 `com.aetikyue.recess`，以及 CI、脚本和文档里的 `--org com.aetikyue`。
- `version/` 目录：原作者各版本的 Hormone.apk 和更新日志，共 674 MB。
- 原作者写的两份设计稿：`docs/system_design.md` 和 `hormone-technical-plan.md`。
- 截图 EXIF 里嵌着原作者手机上的 `com.hormone.hormone`。

用户要把这些全部换成自己的身份。项目按 MIT 协议使用。下面是用户已确认的决定，不要再改动方向：

1. 新包名为 `io.github.jiangkaiqi2005.recess`，flutter create 的 org 为 `io.github.jiangkaiqi2005`。
2. 新建 MIT `LICENSE`，写两行版权。MIT 要求保留原版权声明，所以原作者那一行必须留着，这是协议义务，不是可选项。
3. 从仓库删除 `version/` 下的全部内容。

## 要做的事

### 1. 包名换成 io.github.jiangkaiqi2005.recess

凡是 `com.aetikyue` 都要换掉，包括：

- `native_templates/android/app/build.gradle.kts` 的 namespace 和 applicationId。
- 两个 Kotlin 文件的 `package` 行、路径注释，以及所在目录。用 `git mv` 把 `com/aetikyue/recess/` 移到 `io/github/jiangkaiqi2005/recess/`，java 和 kotlin 两棵源码树都要移。
- MethodChannel：Dart 端 `lib/features/update/data/update_installer.dart` 和 Kotlin 端 MainActivity 都改为 `io.github.jiangkaiqi2005.recess/update`，两端必须一致。
- `.github/workflows/release.yml`：`flutter create --org`，以及复制模板的路径。
- `scripts/build_signed_android.ps1` 中的路径，`scripts/verify_signed_apks.ps1` 中的期望包名。
- 测试里的 `packageName`。
- 文档：AGENTS.md、README.md、WIDGET_SETUP.md、UPDATE_SETUP.md、docs/RELEASE.md。

注意：包名的每一段都要以字母开头，`jiangkaiqi2005` 符合要求。

### 2. 新建 LICENSE

在仓库根目录新建标准 MIT 许可证文本，版权部分写成：

```
Copyright (c) 2026 Aetik
Copyright (c) 2026 jiangkaiqi2005
```

原作者的首个提交在 2026-07-26，署名为 Aetik。README 的“开源许可”一节改为指向 `LICENSE`。不要另外加“fork 自某某”之类的致谢文字，用户不要这些。

### 3. 删除 version/ 旧内容

`git rm -r version`。删之前先确认没有代码、测试或脚本读取其中的现有文件。如果有，先报告再处理。

发版的约定要保留：`release.yml` 会读取 `version/${VERSION}/更新日志.md`，读不到时回退到 `--generate-notes`。核实这个回退确实存在，不要改发版逻辑。以后发新版时再新建对应目录。

README 需要配合修改：

- 顶部的“查看更新日志”链接改为 `https://github.com/jiangkaiqi2005/recess/releases`。
- 目录结构说明里 `version/` 那一行改成“发版时新建的更新日志”之类的说法，与 docs/RELEASE.md 的流程保持一致。

### 4. 原作者的设计稿改成 Recess

- `hormone-technical-plan.md` 用 `git mv` 改名为 `recess-technical-plan.md`。
- 文中的 hormone / Hormone 改为 recess / Recess，大小写对应。`docs/system_design.md` 同样处理。
- 只改名称，不改写其他技术内容。如果有其他文件链接到这两份文档，一并更新链接。

### 5. 去掉截图元数据

清除 `docs/screenshots/*.jpg` 的 EXIF/XMP 等元数据，里面有 vivo 截图工具写入的 `com.hormone.hormone`。

- 必须**无损**：不重新编码像素，例如用 exiftool 的 `-all=`，或 jpegtran 的 `-copy none`。用什么工具看本机有什么。
- 如果本机都没有，报告情况，不要改用有损的重新保存。
- 完成后 `grep -a -i hormone` 应当搜不到任何内容，图片尺寸不变，图片能正常打开。

## 不要改的

- **旧备份兼容**：`backup_repository.dart` 中接受 `'app': 'hormone'` 的逻辑及其测试保留。那是用户把自己旧 app 的数据搬过来的唯一通道，不属于原作者的东西。
- git 历史和提交作者：不改写历史，不 force push。
- 本地 git remote `upstream`：它不在仓库内容里，不用管。
- 未跟踪的 `.agents/` 不属于本任务，`android/`、`build/`、`*.g.dart` 也不要提交。

## 验收

1. `git grep -n -i -E "aetik|com\.hormone"` 只剩 LICENSE 里那一行原作者版权。
2. `git grep -n -i hormone` 只剩旧备份兼容的代码、注释和测试。
3. `dart run build_runner build --delete-conflicting-outputs` 之后，`flutter analyze --fatal-infos --fatal-warnings` 无问题，`flutter test` 全部通过；`scripts` 下的 python 测试也要通过。
4. 本地 `android/` 是 gitignore 的，里面还是旧包名，按新包名重建：
   - 先把现有 `android/` 移动备份到 `C:\Users\25330\AppData\Local\Temp\claude\D--Hormone\7158d7f4-d9e9-451f-b960-48fd1444beca\scratchpad\android_backup_aetikyue\`。
   - 按 release.yml 的方式 `flutter create --org io.github.jiangkaiqi2005`，再复制模板。
   - 带回 `local.properties`，并在 `gradle.properties` 末尾保留 `kotlin.incremental=false`。没有这一行，会因为 C 盘的 Pub 缓存和 D 盘的工程跨盘导致 Kotlin 增量编译报错。
   - 重新生成图标和启动图。
   - `flutter create` 会改写 pubspec.lock，记得恢复。
5. `flutter build apk --debug` 成功；`aapt dump badging` 显示 package 为 `io.github.jiangkaiqi2005.recess`，label 为 `Recess`。**不要安装到手机**：手机上已经有用户测过的版本，要不要再装一个由用户决定。
6. 提交到 `my-version`，提交信息格式为 `<type>(<scope>): <中文描述>`，本规格文件一并提交。不要 push。
