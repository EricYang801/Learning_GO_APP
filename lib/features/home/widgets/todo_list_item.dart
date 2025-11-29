import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/todo.dart';

/// 獨立的 To-Do 項目 Widget
/// 每個項目有自己的 checkbox 狀態和 Timer，不會被父層 rebuild 影響
class TodoListItem extends StatefulWidget {
  final Todo todo;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const TodoListItem({
    super.key,
    required this.todo,
    required this.onComplete,
    required this.onTap,
  });

  @override
  State<TodoListItem> createState() => _TodoListItemState();
}

class _TodoListItemState extends State<TodoListItem> {
  bool _checked = false;
  Timer? _completeTimer;

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  void _onCheckChanged(bool? value) {
    setState(() => _checked = value ?? false);
    _completeTimer?.cancel();

    if (_checked) {
      // 勾選後 3 秒自動完成
      _completeTimer = Timer(const Duration(seconds: 3), widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 12,
      leading: Checkbox(
        value: _checked,
        onChanged: _onCheckChanged,
        shape: const CircleBorder(),
        activeColor: AppColors.accent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      title: Text(widget.todo.title, style: const TextStyle(fontSize: 16)),
      onTap: widget.onTap,
    );
  }
}
