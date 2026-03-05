import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../screens/task_detail_screen.dart';
import '../state/task_notifier.dart';
import 'task_card.dart';
import 'task_form_sheet.dart';

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  bool _isLoadingEdit = false;

  Future<void> _onEdit() async {
    final id = widget.task.id;

    if (id == null) {
      _showForm(widget.task);
      return;
    }

    setState(() => _isLoadingEdit = true);
    Task detail = widget.task;
    try {
      detail = await ref.read(apiClientProvider).getTaskById(id);
    } catch (_) {
      // usar datos locales si falla el fetch
    } finally {
      if (mounted) setState(() => _isLoadingEdit = false);
    }

    if (mounted) _showForm(detail);
  }

  void _showForm(Task task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskFormSheet(task: task),
    );
  }

  void _onDelete() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${widget.task.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.task.id != null) {
                ref
                    .read(taskNotifierProvider.notifier)
                    .deleteTask(widget.task.id!);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onToggleComplete() async {
    final id = widget.task.id;
    if (id == null) return;

    Task full = widget.task;
    try {
      full = await ref.read(apiClientProvider).getTaskById(id);
    } catch (_) {}

    ref.read(taskNotifierProvider.notifier).updateTask(
          full.copyWith(isCompleted: !full.isCompleted),
        );
  }

  void _onTap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(task: widget.task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TaskCard(
      task: widget.task,
      isLoadingEdit: _isLoadingEdit,
      onToggleComplete: widget.task.id == null ? null : _onToggleComplete,
      onEdit: _onEdit,
      onDelete: _onDelete,
      onTap: _onTap,
    );
  }
}
