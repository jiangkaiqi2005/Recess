import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recess/features/semester/application/semester_form_provider.dart';
import 'package:recess/features/semester/application/semester_providers.dart';
import 'package:recess/features/semester/presentation/semester_screen.dart';

/// 导入起始页的目标学期与新建入口。
class ImportTargetSemester extends ConsumerWidget {
  const ImportTargetSemester({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider);
    return Row(
      children: [
        Expanded(
          child: semester.when(
            data: (value) => Text('将导入到：${value?.name ?? ''}'),
            loading: () => const Text('正在加载学期…'),
            error: (error, _) => Text('加载失败：$error'),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final changed = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SemesterEditSheet(fromImport: true),
            );
            if (changed == true && context.mounted) {
              ref.invalidate(semesterFormProvider);
            }
          },
          child: const Text('新建学期'),
        ),
      ],
    );
  }
}
