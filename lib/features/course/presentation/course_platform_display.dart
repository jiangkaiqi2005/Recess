import 'package:flutter/material.dart';

import 'package:hormone/core/models/course_platform.dart';

/// 课程平台用途的图标，详情面板与编辑页共用。
IconData coursePlatformIcon(CoursePlatformPurpose purpose) => switch (purpose) {
      CoursePlatformPurpose.onlineCourse => Icons.smart_display_outlined,
      CoursePlatformPurpose.lab => Icons.science_outlined,
      CoursePlatformPurpose.homework => Icons.assignment_outlined,
      CoursePlatformPurpose.group => Icons.forum_outlined,
      CoursePlatformPurpose.other => Icons.link,
    };

/// 课程平台条目的标题「用途 · 平台名」，详情面板与编辑页共用。
String coursePlatformTitle(CoursePlatform platform) =>
    '${platform.purpose.label} · ${platform.name}';
