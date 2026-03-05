class Task {
  final int? id;
  final String title;
  final bool isCompleted;
  final String? dueDate;
  final String? comments;
  final String? description;
  final String? tags;
  final String? createdAt;
  final String? updatedAt;

  const Task({
    this.id,
    required this.title,
    required this.isCompleted,
    this.dueDate,
    this.comments,
    this.description,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final isCompletedRaw = json['is_completed'];
    final isCompleted = isCompletedRaw == 1 ||
        isCompletedRaw == true ||
        isCompletedRaw == '1' ||
        (isCompletedRaw is String &&
            ['true', 'yes', '1'].contains(isCompletedRaw.toLowerCase()));
    final rawId = json['task_id'] ?? json['id'];
    final id = rawId == null ? null : int.tryParse(rawId.toString());

    final title = (json['title'] ?? '').toString().trim();

    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted,
      dueDate: (json['due_date'] ?? json['due_date_formatted'])?.toString(),
      comments: json['comments']?.toString(),
      description: json['description']?.toString(),
      tags: json['tags']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Task copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    String? dueDate,
    String? comments,
    String? description,
    String? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap(String token) {
    final map = <String, dynamic>{
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'due_date': dueDate,
      'comments': comments,
      'description': description,
      'tags': tags,
    };
    if (id != null) {
      map['task_id'] = id;
    }
    map['token'] = token;
    return map;
  }
}
