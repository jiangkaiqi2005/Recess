# 教务课程跟随学校作息：实施与评审报告

完成 **1** 个单元，需人工关注 **0** 个，待处理 **0** 个；完成 **1 轮修复**。标准轴、规格轴复审分别为 `approve`，没有未决意见。

日期：2026-10-24。依据[已确认 Spec](specs/2026-10-24-course-clock-follow-section.md)，对应 Issue #7。

## 实施结果

教务导入的课程默认使用当前学校节次作息，不再保存由本地作息推算的独立钟点。课程详情、今日课程、课前提醒与桌面小组件继续经由同一 CourseClock 求值；作息变化仍由现有应用级监听触发小组件更新和提醒重排，没有新增用户操作、后台规则或原生课表计算。

- 使用最小持久化布尔值 `useExplicitTimes` 区分跟随作息与独立钟点，数据库从 v2 升至 v3。
- 缺少标记的旧记录全部默认跟随节次，包括无法区分来源的历史 ICS／JSON 记录。原始钟点及课程标识、教师、教室、周次、颜色、备注、学期和平台关联保留；这项兼容默认没有识别历史来源的含义。
- 新 ICS／普通外部 JSON 有实际独立端点时保留它们；仅 null 端回退节次作息。编辑、复制、勾选、保存及持久化映射携带该语义。
- 新备份记录逐门语义；旧备份恢复默认跟随作息，原始端点保留。无法识别的语义在覆盖前拒绝，原数据保留。
- JSON 明确携带钟点语义时原样保留空串等端点；未标记的普通 JSON 保持原有字符串清理规则。
- 完整多学期备份原本不受 JSON 课程导入入口支持。本次识别后在写入前拒绝，并提示使用既有“从备份恢复”；没有增加学期选择或多学期导入行为。既有课程列表格式继续支持。

## 固定范围与提交

分支：`develop`。初始工作区只有本次已经确认、尚未跟踪的 Spec，已随实施纳入提交；没有混入其他已有改动。

| 角色 | 固定提交 |
| --- | --- |
| 单元基点 `unitBase` | `a4921150f856a31552aca10035361367d16a8d93` |
| 初审代码 `reviewHead` | `b526f087a6742773b721e617fea370ca134b17d6` |
| 最终复审代码 `reviewHead` | `25f7b25e8643a9c8709b116806302a3fb55a84c5` |

| 提交 | 内容 |
| --- | --- |
| `b526f08` | `fix(schedule): 让教务课程随学校作息更新`：持久化、统一求值、导入、备份及流程回归。 |
| `25f7b25` | `fix(import): 保留明确钟点端点并补恢复回归`：处理 SP-01、SP-02。 |

两个评审轴复审使用同一基点至最终代码提交的累计差异。可复核命令：

```powershell
git diff a4921150f856a31552aca10035361367d16a8d93...b526f087a6742773b721e617fea370ca134b17d6
git diff a4921150f856a31552aca10035361367d16a8d93...25f7b25e8643a9c8709b116806302a3fb55a84c5
git log a4921150f856a31552aca10035361367d16a8d93..25f7b25e8643a9c8709b116806302a3fb55a84c5 --oneline
```

本报告及 Spec 状态更新为后续单独的文档归档提交，不属于上述代码复审终点。

## 验证证据

下列检查由实施代理实际运行。协调者核对了提交、差异和诊断探针，没有重复全套检查；两个评审代理均没有重跑全量测试，其门禁结论引用实施代理的实际结果。

| 阶段 | 实际命令 | 结果 |
| --- | --- | --- |
| 首个回归先红 | `flutter test test/course_clock_flow_test.dart --plain-name '顺延后教务课程的详情、今日和提醒一起跟随节次'` | 原代码把教务课程判为已结束，预期为进行中；修复后通过。 |
| 核心链路 | `flutter test test/course_clock_flow_test.dart test/course_detail_sheet_test.dart test/schedule_helpers_test.dart test/reminder_scheduler_test.dart test/widget_clock_test.dart test/import_commit_test.dart test/app_database_migration_test.dart` | 当轮 69 项通过。 |
| 数据库生成 | `dart run build_runner build --delete-conflicting-outputs` | schema 修改后成功生成。当前工具提示该参数已移除并被忽略，生成本身成功。 |
| 初审前静态分析 | `flutter analyze --fatal-infos --fatal-warnings` | 无问题。 |
| 初审前全套 | `flutter test --reporter expanded` | 602 项通过。 |
| SP-01 回归先红 | `flutter test test/course_clock_flow_test.dart --plain-name '明确空开始端导入后不回退或生成臆造提醒'` | 普通 JSON 与 Recess 课程列表均错误生成提醒；修复后通过。 |
| 修复聚焦验证 | `flutter test test/course_clock_flow_test.dart test/backup_repository_test.dart test/import_commit_test.dart test/json_importer_test.dart` | 80 项通过。 |
| 修复后静态分析 | `flutter analyze --fatal-infos --fatal-warnings` | 无问题。 |
| 修复后最终全套 | `flutter test --reporter expanded` | 604 项通过。 |
| 提交前差异检查 | `git diff --cached --check` | 通过。 |

实际使用 SDK 位于 `D:\Flutter\flutter\bin`。第 1 轮修复没有修改 schema，因此未重复代码生成，保留先前生成结果。文档收尾只检查引用和差异，不重复代码门禁。

关键行为证据：

- [课程钟点流程测试](../test/course_clock_flow_test.dart)：真实教务预览及提交周日第 6–9 节、周次 7／9／11／13，分别覆盖先设置后导入、先导入后设置。真实点击周视图详情与连续两次小组件 payload 均为 **14:25–18:05**；今日状态在 14:25 开始、18:05 结束；提前 10 分钟的提醒为 14:15。另有周视图、今日、搜索入口的独立钟点对照，以及编辑、复制、保存和重载验证。
- [真实旧库升级测试](../test/course_clock_upgrade_test.dart)：创建含旧快照的实际 v2 SQLite 磁盘文件，升级后关闭并重新打开。旧教务风格与旧文件风格记录均默认跟随，原始钟点和其他业务信息保留；重启后的实际详情、提醒及小组件结果正确。
- [设置流程测试](../test/section_time_flow_test.dart)：穿过真实设置页顺延、模板、恢复默认、单节开始和时长编辑入口。旧钟点字段仍存在时，详情随新作息更新。既有布局、字号与滚动回归保留。
- [备份测试](../test/backup_repository_test.dart)及[导入提交测试](../test/import_commit_test.dart)：新旧备份、原始空串及无效钟点往返、明确语义、未知语义拒绝、原子性、平台和其他学期保留均受覆盖。恢复旧快照后的提醒与今日状态验证使用当前作息。
- [通知平台测试](../test/notification_clock_test.dart)：捕获实际通知 MethodChannel 数据，以绝对时刻核对提醒。修改作息后取消旧提醒并重排，独立端点课程保持原触发时刻。
- [小组件测试](../test/widget_clock_test.dart)：捕获实际 MethodChannel 课次 payload，覆盖独立端点、逐端回退及无效端点降级。

`lib/data/app_database.g.dart` 实际受 Git 跟踪，完全由 build_runner 生成，没有手改。生成器同时简化了三个 manager 中可推断的泛型参数，随同一份生成结果保留。

## 双轴评审与处置

| 评审轴 | 初审 | 第 1 轮复审 | 未决问题 |
| --- | --- | --- | --- |
| 标准轴 | `approve`，未提出问题。 | `approve`；确认明确标记文件原样保留端点、普通文件原清理不变，符合最小变更与现有分层，无新增标准问题。 | 0 |
| 规格轴 | `changes_requested`，提出 SP-01、SP-02。 | `approve`；分别确认两项已修复，没有新增规格问题。 | 0 |

### SP-01：明确标记 JSON 的空端点被清理成 null

- 原问题：解析器接受 `useExplicitTimes: true`，却把空开始字符串转成 null，导致回退到学校作息并生成文件没有提供的提醒。
- 处置：`fixed`。只对明确携带钟点语义的 JSON 原样保留起止端点，未标记的普通 JSON 保持原清理行为，合法 true／false 及未知值拒绝规则保留。
- 新回归：普通 JSON 和 Recess 课程列表经过真实提交及持久化后，空开始端不生成提醒，今日状态降级，小组件开始端为空，结束端仍为 `19:45`。回归在修正前实际失败。
- 复审：规格轴认可修复；标准轴确认没有引入新的约定问题。

### SP-02：旧备份恢复缺少最终钟点结果验证

- 原问题：旧备份测试只断言标记、原始字段与往返，没有证明恢复后实际使用当前作息。
- 处置：`fixed`。在原有真实备份恢复测试中增加公开派生结果验证，不新增框架。
- 新回归：保留原始 `08:00–09:35`，当前作息对应 `14:25–18:05`；提醒实际为 `14:15`，`17:00` 今日课程仍为进行中，证明旧快照没有主导结果。
- 复审：规格轴认可补充验证；标准轴无新增问题。

没有 `rejected` 或尚未核实的意见，没有依赖阻塞。

## 尚未覆盖与交付边界

- 未进行 Android 真机升级、桌面实际自动刷新或系统实际通知投递验收。自动化中的真实数据库及 MethodChannel 结果不替代真机证据。
- 未读取本次用户手机数据库，未构建、安装 APK，也未改动手机数据。
- 未推送、创建 PR、发布版本，未更新、评论或关闭 GitHub Issue。
- 如后续需要发布安装包，再单独执行真机升级、桌面刷新和通知验收；本次授权的实施与双轴评审已完成。
