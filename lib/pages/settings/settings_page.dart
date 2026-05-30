import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../models/timer_state.dart';
import '../../models/user_settings.dart' as models;
import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../database/app_database.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // 角色切换
            const _SectionTitle('角色'),
            ListTile(
              title: const Text('当前角色'),
              subtitle: Text(settings.currentRole == models.UserRole.parent
                  ? '家长'
                  : '孩子'),
              trailing: SegmentedButton<models.UserRole>(
                segments: const [
                  ButtonSegment(value: models.UserRole.parent, label: Text('家长')),
                  ButtonSegment(value: models.UserRole.child, label: Text('孩子')),
                ],
                selected: {settings.currentRole},
                onSelectionChanged: (roles) => ref
                    .read(settingsProvider.notifier)
                    .setRole(roles.first),
              ),
            ),

            const Divider(),

            // 计时器默认设置
            const _SectionTitle('计时器'),
            ListTile(
              title: const Text('默认计时模式'),
              trailing: SegmentedButton<TimerMode>(
                segments: const [
                  ButtonSegment(value: TimerMode.countup, label: Text('正计时')),
                  ButtonSegment(
                      value: TimerMode.countdown, label: Text('倒计时')),
                ],
                selected: {settings.defaultTimerMode},
                onSelectionChanged: (modes) => ref
                    .read(settingsProvider.notifier)
                    .setDefaultTimerMode(modes.first),
              ),
            ),
            if (settings.defaultTimerMode == TimerMode.countdown)
              ListTile(
                title: const Text('默认倒计时分钟数'),
                trailing: Text('${settings.defaultCountdownMinutes} 分钟'),
                subtitle: Slider(
                  value: settings.defaultCountdownMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${settings.defaultCountdownMinutes} 分钟',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setDefaultCountdownMinutes(v.round()),
                ),
              ),

            const Divider(),

            // 主题
            const _SectionTitle('外观'),
            ListTile(
              title: const Text('主题模式'),
              trailing: SegmentedButton<models.ThemeMode>(
                segments: const [
                  ButtonSegment(value: models.ThemeMode.light, label: Text('浅色')),
                  ButtonSegment(value: models.ThemeMode.dark, label: Text('深色')),
                  ButtonSegment(value: models.ThemeMode.system, label: Text('跟随系统')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (modes) => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(modes.first),
              ),
            ),

            const Divider(),

            // 科目管理
            const _SectionTitle('科目管理'),
            const _SubjectManagementList(),

            const Divider(),

            // 类型管理
            const _SectionTitle('类型管理'),
            const _StudyTypeManagementList(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载设置失败: $e')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SubjectManagementList extends ConsumerWidget {
  const _SubjectManagementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(allSubjectsProvider);

    return subjectsAsync.when(
      data: (subjects) => Column(
        children: [
          ...subjects.map((s) => ListTile(
                leading: Text(s.icon, style: const TextStyle(fontSize: 24)),
                title: Text(s.name),
                trailing: s.isCustom
                    ? IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () async {
                          await ref
                              .read(subjectsDaoProvider)
                              .deleteSubject(s.id);
                          ref.read(subjectsRefreshProvider.notifier).state++;
                        },
                      )
                    : null,
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加自定义科目'),
            onTap: () => _showAddSubjectDialog(context, ref),
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedIcon = '📚';
    String selectedColor = '#2196F3';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加科目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '科目名称'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(subjectsDaoProvider).insertSubject(
                      SubjectsCompanion.insert(
                        id: const Uuid().v4(),
                        name: nameController.text,
                        icon: selectedIcon,
                        color: selectedColor,
                        isCustom: const drift.Value(true),
                      ),
                    ).then((_) {
                  ref.read(subjectsRefreshProvider.notifier).state++;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _StudyTypeManagementList extends ConsumerWidget {
  const _StudyTypeManagementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(allStudyTypesProvider);

    return typesAsync.when(
      data: (types) => Column(
        children: [
          ...types.map((t) => ListTile(
                title: Text(t.name),
                trailing: t.isCustom
                    ? IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () async {
                          await ref
                              .read(subjectsDaoProvider)
                              .deleteStudyType(t.id);
                          ref.read(studyTypesRefreshProvider.notifier).state++;
                        },
                      )
                    : null,
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加自定义类型'),
            onTap: () => _showAddTypeDialog(context, ref),
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAddTypeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加类型'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '类型名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(subjectsDaoProvider).insertStudyType(
                      StudyTypesCompanion.insert(
                        id: const Uuid().v4(),
                        name: nameController.text,
                        isCustom: const drift.Value(true),
                      ),
                    ).then((_) {
                  ref.read(studyTypesRefreshProvider.notifier).state++;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
