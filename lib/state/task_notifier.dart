import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/task.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('ApiClient no configurado en el provider');
});

class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TaskNotifier(this._apiClient) : super(const AsyncValue.data([]));

  final ApiClient _apiClient;

  Future<void> fetchTasks() async {
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncValue.loading();
    }
    try {
      final tasks = await _apiClient.getTasks();
      // merge con estado previo para no perder description/tags/comments al recargar
      final merged = _mergeListWithPrevious(tasks, previous ?? []);
      state = AsyncValue.data(merged);
      _enrichTasksInBackground(merged);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createTask(Task task) async {
    Task created = await _apiClient.createTask(task);
    created = _mergeWithSent(created, task);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, created]);
  }

  List<Task> _mergeListWithPrevious(List<Task> fromApi, List<Task> previous) {
    if (previous.isEmpty) return fromApi;
    final byId = {for (final t in previous) if (t.id != null) t.id!: t};
    return [
      for (final t in fromApi)
        t.id != null && byId.containsKey(t.id!)
            ? _mergeWithPrevious(t, byId[t.id!]!)
            : t,
    ];
  }

  bool _needsEnrichment(Task t) =>
      t.id != null &&
      (t.description?.trim().isEmpty ?? true) &&
      (t.comments?.trim().isEmpty ?? true) &&
      (t.tags?.trim().isEmpty ?? true);

  void _enrichTasksInBackground(List<Task> list) {
    for (final t in list) {
      if (!_needsEnrichment(t)) continue;
      final id = t.id!;
      Future.microtask(() => _enrichTaskById(id));
    }
  }

  Future<void> _enrichTaskById(int id) async {
    try {
      final full = await _apiClient.getTaskById(id);
      final current = state.valueOrNull ?? [];
      if (current.isEmpty) return;
      final updated = [
        for (final t in current) t.id == id ? _mergeWithPrevious(full, t) : t,
      ];
      state = AsyncValue.data(updated);
    } catch (_) {}
  }

  Task _mergeWithPrevious(Task fromApi, Task previous) {
    final hasDescription = (fromApi.description?.trim().isEmpty ?? true) == false;
    final hasComments = (fromApi.comments?.trim().isEmpty ?? true) == false;
    final hasTags = (fromApi.tags?.trim().isEmpty ?? true) == false;
    if (hasDescription && hasComments && hasTags) return fromApi;
    return Task(
      id: fromApi.id,
      title: fromApi.title,
      isCompleted: fromApi.isCompleted,
      dueDate: fromApi.dueDate,
      description: hasDescription ? fromApi.description : (previous.description ?? fromApi.description),
      comments: hasComments ? fromApi.comments : (previous.comments ?? fromApi.comments),
      tags: hasTags ? fromApi.tags : (previous.tags ?? fromApi.tags),
      createdAt: fromApi.createdAt,
      updatedAt: fromApi.updatedAt,
    );
  }

  // prioriza datos enviados por si la API devuelve campos vacíos
  Task _mergeWithSent(Task fromApi, Task sent) {
    return Task(
      id: fromApi.id,
      title: fromApi.title.isEmpty ? sent.title : fromApi.title,
      isCompleted: sent.isCompleted,
      dueDate: fromApi.dueDate ?? sent.dueDate,
      comments: fromApi.comments ?? sent.comments,
      description: fromApi.description ?? sent.description,
      tags: fromApi.tags ?? sent.tags,
      createdAt: fromApi.createdAt,
      updatedAt: fromApi.updatedAt,
    );
  }

  Future<void> updateTask(Task task) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final t in previous) t.id == task.id ? task : t,
    ]);
    try {
      Task updated = await _apiClient.updateTask(task);
      updated = _mergeWithSent(updated, task);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([
        for (final t in current) t.id == updated.id ? updated : t,
      ]);
    } catch (_) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    await _apiClient.deleteTask(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((t) => t.id != id).toList());
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TaskNotifier(apiClient);
});
