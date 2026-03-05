import 'package:flutter/material.dart';

import '../models/task.dart';

enum _MenuAction { edit, delete }

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    this.onToggleComplete,
    this.onTap,
    this.isLoadingEdit = false,
  });

  final Task task;
  final VoidCallback? onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isLoadingEdit;

  bool get _isOverdue {
    if (task.dueDate == null || task.isCompleted) return false;
    final due = DateTime.tryParse(task.dueDate!);
    if (due == null) return false;
    final today = DateTime.now();
    return due.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCompleted = task.isCompleted;

    final bool hasChips = task.dueDate != null ||
        (task.tags?.isNotEmpty ?? false) ||
        (task.comments?.isNotEmpty ?? false);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: isCompleted
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? colorScheme.outlineVariant.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Checkbox(
                  value: isCompleted,
                  onChanged:
                      onToggleComplete == null ? null : (_) => onToggleComplete!(),
                  shape: const CircleBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 14, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title.isEmpty ? 'Sin título' : task.title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isCompleted ? FontWeight.normal : FontWeight.w600,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: colorScheme.onSurfaceVariant,
                          color: isCompleted
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (task.description?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isLoadingEdit)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<_MenuAction>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Opciones',
                  onSelected: (action) {
                    switch (action) {
                      case _MenuAction.edit:
                        onEdit();
                      case _MenuAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: _MenuAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.delete,
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                        title: Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (hasChips)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (task.dueDate != null)
                    _TaskChip(
                      icon: _isOverdue
                          ? Icons.calendar_today_rounded
                          : Icons.calendar_today_outlined,
                      label: task.dueDate!,
                      bgColor: _isOverdue
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer.withValues(alpha: 0.7),
                      fgColor: _isOverdue
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                    ),
                  if (task.tags?.isNotEmpty ?? false)
                    _TaskChip(
                      icon: Icons.label_outline_rounded,
                      label: task.tags!,
                      bgColor:
                          colorScheme.secondaryContainer.withValues(alpha: 0.7),
                      fgColor: colorScheme.onSecondaryContainer,
                    ),
                  if (task.comments?.isNotEmpty ?? false)
                    _TaskChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: task.comments!,
                      bgColor:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                      fgColor: colorScheme.onTertiaryContainer,
                      maxWidth: 220,
                    ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    this.maxWidth,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
