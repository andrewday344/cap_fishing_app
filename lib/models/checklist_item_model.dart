class ChecklistItem {
  final String id;
  final String task;
  bool isCompleted;
  final String category; // e.g., 'Vessel', 'Safety', 'Trailer'

  ChecklistItem({
    required this.id,
    required this.task,
    this.isCompleted = false,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'task': task,
    'isCompleted': isCompleted,
    'category': category,
  };

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
    id: map['id'],
    task: map['task'],
    isCompleted: map['isCompleted'] ?? false,
    category: map['category'],
  );
}