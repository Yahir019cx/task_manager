import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiClient {
  final Dio _dio;
  final String _token;

  ApiClient({
    required String baseUrl,
    required String bearerToken,
    required String token,
  })  : _token = token,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $bearerToken',
          },
        ));

  List<Task> _parseTaskList(dynamic data) {
    if (data is! List) {
      throw Exception('No hay una lista de tareas');
    }
    return data.map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Task _parseSingleTask(dynamic data) {
    Map<String, dynamic>? map;
    if (data is List && data.isNotEmpty) {
      map = Map<String, dynamic>.from(data.first as Map);
    } else if (data is Map) {
      final d = Map<String, dynamic>.from(data);
      // respuesta anidada en task/data
      map = d['task'] != null
          ? Map<String, dynamic>.from(d['task'] as Map)
          : d['data'] != null
              ? Map<String, dynamic>.from(d['data'] as Map)
              : d;
    }
    if (map == null) throw Exception('Respuesta de tarea inválida');
    return Task.fromJson(map);
  }

  String _toFormEncoded(Map<String, dynamic> map) {
    return map.entries
        .where((e) => e.value != null)
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  Future<List<Task>> getTasks() async {
    try {
      final response = await _dio.get(
        '/tasks',
        queryParameters: {'token': _token},
      );
      return _parseTaskList(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.message ?? 'Error al cargar las tareas');
    }
  }

  Future<Task> getTaskById(int id) async {
    try {
      final response = await _dio.get(
        '/tasks/$id',
        queryParameters: {'token': _token, 'task_id': id},
      );
      return _parseSingleTask(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.message ?? 'Error al cargar la tarea');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final body = task.toMap(_token);
      body.remove('task_id');
      final response = await _dio.post(
        '/tasks',
        data: _toFormEncoded(body),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return _parseSingleTask(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.message ?? 'Error al crear la tarea');
    }
  }

  Future<Task> updateTask(Task task) async {
    final id = task.id;
    if (id == null) throw Exception('La tarea debe tener id para actualizarla');
    try {
      final body = task.toMap(_token);
      body.remove('task_id');
      final response = await _dio.put(
        '/tasks/$id',
        queryParameters: {'task_id': id},
        data: _toFormEncoded(body),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return _parseSingleTask(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.message ?? 'Error al actualizar la tarea');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete(
        '/tasks/$id',
        queryParameters: {'token': _token, 'task_id': id},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.message ?? 'Error al eliminar la tarea');
    }
  }
}
