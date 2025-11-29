import 'package:flutter/foundation.dart';
import '../../../core/models/todo.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/id.dart';

/// To-Do 狀態管理
class TodoState extends ChangeNotifier {
  static const _storageKey = 'todos';

  List<Todo> _todos = [];

  /// 所有待辦事項
  List<Todo> get todos => List.unmodifiable(_todos);

  /// 未完成的待辦事項（依到期日排序）
  List<Todo> get visibleTodos =>
      _todos.where((t) => !t.isDone).toList()
        ..sort((a, b) => a.due.compareTo(b.due));

  /// 今天到期的待辦事項
  List<Todo> todayTodos(DateTime now) {
    return _todos.where((t) {
      return t.due.year == now.year &&
          t.due.month == now.month &&
          t.due.day == now.day;
    }).toList();
  }

  /// 今天的完成數量
  int todayDoneCount(DateTime now) {
    return todayTodos(now).where((t) => t.isDone).length;
  }

  /// 今天的總數量
  int todayTotalCount(DateTime now) {
    return todayTodos(now).length;
  }

  /// 載入資料
  Future<void> load() async {
    final list = await StorageService.instance.getList(_storageKey);
    _todos = list
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();
    _sort();
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.setJson(
      _storageKey,
      _todos.map((t) => t.toJson()).toList(),
    );
  }

  void _sort() {
    _todos.sort((a, b) => a.due.compareTo(b.due));
  }

  /// 新增待辦
  Future<void> add({
    required String title,
    required String desc,
    required DateTime due,
  }) async {
    final todo = Todo(
      id: IdUtils.generate(),
      title: title,
      desc: desc,
      due: due,
    );
    _todos.add(todo);
    _sort();
    await _save();
    notifyListeners();
  }

  /// 更新待辦
  Future<void> update({
    required String id,
    required String title,
    required String desc,
    required DateTime due,
  }) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = _todos[index].copyWith(
        title: title,
        desc: desc,
        due: due,
      );
      _sort();
      await _save();
      notifyListeners();
    }
  }

  /// 標記完成
  Future<void> complete(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = _todos[index].copyWith(doneAt: DateTime.now());
      await _save();
      notifyListeners();
    }
  }

  /// 取消完成
  Future<void> uncomplete(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = _todos[index].copyWith(clearDoneAt: true);
      await _save();
      notifyListeners();
    }
  }

  /// 刪除待辦
  Future<void> remove(String id) async {
    _todos.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  /// 根據 ID 取得待辦
  Todo? getById(String id) {
    try {
      return _todos.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
