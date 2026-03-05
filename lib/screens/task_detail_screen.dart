import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../state/task_notifier.dart';
import '../widgets/task_form_sheet.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(taskNotifierProvider);
    final current = tasksState.valueOrNull?.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    ) ?? task;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void onEdit() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => TaskFormSheet(task: current),
      );
    }

    void onDelete() {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar tarea?'),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${current.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (current.id != null) {
                  ref.read(taskNotifierProvider.notifier).deleteTask(current.id!);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de tarea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            current.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: current.isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: colorScheme.onSurfaceVariant,
              color: current.isCompleted
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusChip(isCompleted: current.isCompleted),
              if (current.dueDate != null)
                _DueDateChip(dueDate: current.dueDate!, isCompleted: current.isCompleted),
            ],
          ),
          if (current.createdAt != null || current.updatedAt != null) ...[
            const SizedBox(height: 8),
            _TimestampsRow(createdAt: current.createdAt, updatedAt: current.updatedAt),
          ],
          const SizedBox(height: 24),
          if (current.description?.isNotEmpty ?? false) ...[
            _DetailSection(
              icon: Icons.notes_rounded,
              label: 'Descripción',
              content: current.description!,
            ),
            const SizedBox(height: 12),
          ],
          if (current.comments?.isNotEmpty ?? false) ...[
            _DetailSection(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Comentarios',
              content: current.comments!,
            ),
            const SizedBox(height: 12),
          ],
          if (current.tags?.isNotEmpty ?? false)
            _DetailSection(
              icon: Icons.label_outline_rounded,
              label: 'Etiquetas',
              content: current.tags!,
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isCompleted
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? 'Completada' : 'Pendiente',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.dueDate, required this.isCompleted});

  final String dueDate;
  final bool isCompleted;

  bool get _isOverdue {
    if (isCompleted) return false;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    final today = DateTime.now();
    return due.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overdue = _isOverdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: overdue ? colorScheme.errorContainer : colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: overdue ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            dueDate,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: overdue ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.label,
    required this.content,
  });

  final IconData icon;
  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimestampsRow extends StatelessWidget {
  const _TimestampsRow({this.createdAt, this.updatedAt});

  final String? createdAt;
  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (createdAt != null)
          _TimestampRow(
            icon: Icons.access_time_rounded,
            label: 'Creada',
            value: createdAt!,
          ),
        if (updatedAt != null)
          _TimestampRow(
            icon: Icons.edit_calendar_outlined,
            label: 'Actualizada',
            value: updatedAt!,
          ),
      ],
    );
  }
}

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
