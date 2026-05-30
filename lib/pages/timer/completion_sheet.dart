import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/records_provider.dart';

class CompletionSheet extends ConsumerStatefulWidget {
  final String recordId;

  const CompletionSheet({super.key, required this.recordId});

  @override
  ConsumerState<CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends ConsumerState<CompletionSheet> {
  double _accuracy = 3;
  double _focus = 3;
  double _speed = 3;
  double _difficulty = 3;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('完成情况',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSlider('🎯 正确率', _accuracy, (v) => setState(() => _accuracy = v)),
          _buildSlider('🧠 专注度', _focus, (v) => setState(() => _focus = v)),
          _buildSlider('⚡ 完成速度', _speed, (v) => setState(() => _speed = v)),
          _buildSlider('💪 难易度', _difficulty, (v) => setState(() => _difficulty = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注（选填）',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 24, child: Text('${value.round()}')),
      ],
    );
  }

  void _save() {
    final rating = CompletionRatingsCompanion.insert(
      recordId: widget.recordId,
      accuracy: _accuracy.round(),
      focus: _focus.round(),
      speed: _speed.round(),
      difficulty: _difficulty.round(),
      note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
    );
    ref.read(recordsDaoProvider).insertRating(rating).then((_) {
      ref.invalidate(todayRecordsProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
