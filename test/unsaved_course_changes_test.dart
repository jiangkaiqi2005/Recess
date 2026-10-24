import 'package:flutter_test/flutter_test.dart';

import 'package:recess/core/models/course.dart';
import 'package:recess/core/models/course_platform.dart';
import 'package:recess/features/course/domain/unsaved_course_changes.dart';

const _initial = Course(
  id: 'c1',
  semesterId: 's1',
  name: '操作系统',
  teacher: '张三',
  location: '教三-201',
  notes: '带书',
  dayOfWeek: 1,
  startSection: 1,
  endSection: 2,
  startTime: '08:00',
  endTime: '09:40',
  weeks: [1, 2, 3],
  colorValue: 0xFF4399F1,
);

const _platform = CoursePlatform(
  purpose: CoursePlatformPurpose.onlineCourse,
  name: '学习通',
);

Course draftFrom(Course initial) => Course(
  id: initial.id,
  semesterId: initial.semesterId,
  name: initial.name,
  teacher: initial.teacher,
  location: initial.location,
  notes: initial.notes,
  dayOfWeek: initial.dayOfWeek,
  startSection: initial.startSection,
  endSection: initial.endSection,
  startTime: initial.startTime,
  endTime: initial.endTime,
  weeks: initial.weeks,
  colorValue: initial.colorValue,
);

void main() {
  bool changed({
    Course? draft,
    Course initial = _initial,
    List<CoursePlatform> platforms = const [_platform],
    List<CoursePlatform> initialPlatforms = const [_platform],
  }) => hasUnsavedCourseChanges(
    draft: draft ?? draftFrom(initial),
    initial: initial,
    platforms: platforms,
    initialPlatforms: initialPlatforms,
  );

  test('与初始内容一致（含新建空白草稿）时无未保存差异', () {
    expect(changed(), isFalse);
    expect(
      hasUnsavedCourseChanges(
        draft: const Course(
          id: '',
          semesterId: 's1',
          name: '',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [],
        ),
        initial: const Course(
          id: '',
          semesterId: 's1',
          name: '',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [],
        ),
        platforms: const [],
        initialPlatforms: const [],
      ),
      isFalse,
    );
  });

  test('可编辑字段任一实际差异都算未保存', () {
    expect(changed(draft: draftFrom(_initial).copyWith(name: '编译原理')), isTrue);
    expect(changed(draft: draftFrom(_initial).copyWith(teacher: '李四')), isTrue);
    expect(
      changed(draft: draftFrom(_initial).copyWith(location: '教一-101')),
      isTrue,
    );
    // copyWith 的 null 合并语义无法清空字段，用直接构造表达“备注被清空”。
    final notesCleared = draftFrom(_initial);
    expect(
      changed(
        draft: Course(
          id: notesCleared.id,
          semesterId: notesCleared.semesterId,
          name: notesCleared.name,
          teacher: notesCleared.teacher,
          location: notesCleared.location,
          notes: null,
          dayOfWeek: notesCleared.dayOfWeek,
          startSection: notesCleared.startSection,
          endSection: notesCleared.endSection,
          weeks: notesCleared.weeks,
          colorValue: notesCleared.colorValue,
        ),
      ),
      isTrue,
    );
    expect(changed(draft: draftFrom(_initial).copyWith(dayOfWeek: 3)), isTrue);
    expect(
      changed(draft: draftFrom(_initial).copyWith(startSection: 2)),
      isTrue,
    );
    expect(changed(draft: draftFrom(_initial).copyWith(endSection: 4)), isTrue);
    expect(
      changed(draft: draftFrom(_initial).copyWith(colorValue: 0xFF4BA89A)),
      isTrue,
    );
  });

  test('周次按集合比较：同集不同序不算改动，增删算改动', () {
    expect(
      changed(draft: draftFrom(_initial).copyWith(weeks: [3, 1, 2])),
      isFalse,
    );
    expect(changed(draft: draftFrom(_initial).copyWith(weeks: [1, 2])), isTrue);
    expect(
      changed(draft: draftFrom(_initial).copyWith(weeks: [1, 2, 3, 4])),
      isTrue,
    );
  });

  test('课程平台草稿差异与顺序变化都算未保存', () {
    expect(changed(platforms: const []), isTrue);
    expect(
      changed(
        platforms: const [
          _platform,
          CoursePlatform(purpose: CoursePlatformPurpose.lab, name: '头歌'),
        ],
      ),
      isTrue,
    );
    expect(
      changed(
        platforms: const [_platform],
        initialPlatforms: const [
          _platform,
          CoursePlatform(purpose: CoursePlatformPurpose.lab, name: '头歌'),
        ],
      ),
      isTrue,
    );
    // 内容相同仅顺序不同：顺序即展示顺序，算改动。
    expect(
      changed(
        platforms: const [
          CoursePlatform(purpose: CoursePlatformPurpose.lab, name: '头歌'),
          _platform,
        ],
      ),
      isTrue,
    );
  });

  test('不可编辑字段（id/学期/钟点）不参与判定', () {
    expect(changed(draft: draftFrom(_initial).copyWith(id: 'c2')), isFalse);
    expect(
      changed(draft: draftFrom(_initial).copyWith(startTime: '08:05')),
      isFalse,
    );
  });
}
