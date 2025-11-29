import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/homework.dart';

/// 獨立的 Homework 項目 Widget
/// 每個項目有自己的 checkbox 狀態和 Timer，不會被父層 rebuild 影響
class HomeworkListItem extends StatefulWidget {
  final Homework homework;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const HomeworkListItem({
    super.key,
    required this.homework,
    required this.onComplete,
    required this.onTap,
  });

  @override
  State<HomeworkListItem> createState() => _HomeworkListItemState();
}

class _HomeworkListItemState extends State<HomeworkListItem> {
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
    final h = widget.homework;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 12,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: Color(
                int.tryParse(h.color ?? '', radix: 16) ?? 0xFFFFA000,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      title: Text(h.title, style: const TextStyle(fontSize: 16)),
      trailing: Checkbox(
        value: _checked,
        onChanged: _onCheckChanged,
        activeColor: AppColors.accent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onTap: widget.onTap,
    );
  }
}
