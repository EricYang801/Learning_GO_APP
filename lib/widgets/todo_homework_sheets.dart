import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/ios_time_picker.dart';

// 共用：欄位圓角（和按鈕一致）
const double _kFieldRadius = 12;

// 共用：產生輸入框樣式（淺灰底、深灰框、同圓角）
InputDecoration _decoration({
  String? hint,
  EdgeInsetsGeometry? contentPadding,
}) {
  final base = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    borderSide: BorderSide(color: Colors.grey[400]!),
  );
  final focused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    borderSide: BorderSide(color: Colors.grey[500]!, width: 1.2),
  );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[100],
    isDense: true,
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    enabledBorder: base,
    focusedBorder: focused,
    border: base,
  );
}

Widget _dateBox({
  required BuildContext context,
  required DateTime value,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(_kFieldRadius),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 顯示已選日期（沿用你的 humanDue）
          Text(humanDue(value)),
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Colors.grey[600],
          ),
        ],
      ),
    ),
  );
}

// 讓 Dropdown 外框與 TextField 一致時，額外控制高度
Widget _denseDropdownWrapper({required Widget child}) {
  return SizedBox(
    height: 40, // ≈ 你的 Title 輸入框高度（10 + 20 + 字高），可微調
    child: child,
  );
}

Widget _colorStrip({
  required List<Color> options,
  required Color selected,
  required ValueChanged<Color> onChanged,
}) {
  return InputDecorator(
    // 用跟 Title 完全相同的外觀與 padding
    decoration: _decoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    ),
    child: SizedBox(
      height: 35, // 內容區 20，加上上下 10 padding -> 總高 40，與 Title 一樣
      width: double.infinity, // 撐滿寬度（跟 TextField 一樣）
      child: ListView(
        scrollDirection: Axis.horizontal, // 水平可滑動
        children: options.map((c) {
          final isSelected = c.value == selected.value;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 12),
              // 圓形尺寸
              width: isSelected ? 35 : 30,
              height: isSelected ? 35 : 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c,
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
                border: Border.all(
                  color: isSelected ? Colors.black26 : Colors.grey[400]!,
                  width: isSelected ? 1.2 : 1, // 被選中時更明顯
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

// ============================
// AddTodoSheet
// ============================

class AddTodoSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AddTodoSheet({super.key, this.existing});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final title = TextEditingController();
  final desc = TextEditingController();
  DateTime due = DateTime.now().add(const Duration(days: 1));

  bool titleError = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      title.text = widget.existing!['title'];
      desc.text = widget.existing!['desc'] ?? '';
      due = DateTime.parse(widget.existing!['due']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existing == null ? 'New To-Do' : 'Edit To-Do',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Title（獨立標籤 + 矮一點的輸入框）
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'To-Do Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: title,
            maxLines: 1,
            decoration: _decoration(
              hint: 'Enter To-Do title',
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
            ).copyWith(errorText: titleError ? 'Title is required' : null),
            onChanged: (_) {
              if (titleError && title.text.trim().isNotEmpty) {
                setState(() => titleError = false);
              }
            },
          ),
          const SizedBox(height: 10),

          // Description（較高、可捲動）
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: desc,
            minLines: 4,
            maxLines: 8, // 超過會在欄位內滾動
            decoration: _decoration(hint: 'Add description (optional)...'),
          ),
          const SizedBox(height: 10),

          // Due Date（獨立標籤 + 可點擊灰底框）
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Due Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          _dateBox(
            context: context,
            value: due,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
                initialDate: due,
              );
              if (d != null) setState(() => due = d);
            },
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              if (widget.existing != null)
                TextButton.icon(
                  onPressed: () {
                    // ✅ 直接刪除（不保留）
                    app.removeTodo(widget.existing!['id']);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // 修改底色
                ),
                onPressed: () {
                  if (title.text.trim().isEmpty) {
                    setState(() => titleError = true);
                    return;
                  }

                  if (widget.existing == null) {
                    app.addTodo(title.text, desc.text, due);
                  } else {
                    app.updateTodo(
                      widget.existing!['id'],
                      title.text,
                      desc.text,
                      due,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================
// AddHomeworkSheet
// ============================

class AddHomeworkSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AddHomeworkSheet({super.key, this.existing});

  @override
  State<AddHomeworkSheet> createState() => _AddHomeworkSheetState();
}

class _AddHomeworkSheetState extends State<AddHomeworkSheet> {
  final title = TextEditingController();
  final content = TextEditingController();

  DateTime due = DateTime.now().add(const Duration(days: 1));
  String reminderType = 'None';
  DateTime? reminderAt;
  Color color = Colors.orange;

  final reminderOptions = const [
    'None',
    '1 day before (9am)',
    'Due morning (9am)',
    '3 hours before',
    'Custom',
  ];

  bool titleError = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      title.text = e['title'];
      content.text = e['content'] ?? '';
      due = DateTime.parse(e['due']);
      reminderType = e['reminderType'] ?? 'None';
      reminderAt = e['reminderAt'] != null
          ? DateTime.tryParse(e['reminderAt'])
          : null;
      color = Color(e['color'] ?? Colors.orange.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null ? 'New Homework' : 'Edit Homework',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Title（獨立標籤 + 矮一點的輸入框）
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Homework Title',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: title,
              maxLines: 1,
              decoration: _decoration(
                hint: 'Enter homework title',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ).copyWith(errorText: titleError ? 'Title is required' : null),
              onChanged: (_) {
                if (titleError && title.text.trim().isNotEmpty) {
                  setState(() => titleError = false);
                }
              },
            ),

            const SizedBox(height: 10),

            // Content（較高、可捲動）
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Homework Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: content,
              minLines: 5,
              maxLines: 10, // 超過會在欄位內滾動
              decoration: _decoration(
                hint: 'Describe the content (optional)...',
              ),
            ),
            const SizedBox(height: 10),

            // Due Date（獨立標籤 + 可點擊灰底框）
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Due Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            _dateBox(
              context: context,
              value: due,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                  initialDate: due,
                );
                if (d != null) setState(() => due = d);
              },
            ),
            const SizedBox(height: 10),

            // Reminder
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: _decoration(contentPadding: EdgeInsets.zero),
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: _denseDropdownWrapper(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      iconSize: 24,
                      borderRadius: BorderRadius.circular(_kFieldRadius),
                      dropdownColor: Colors.white,
                      elevation: 3,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),

                      value: reminderType,

                      // 👇 收合後顯示的文字（客製 Custom 加上括號）
                      selectedItemBuilder: (context) {
                        return reminderOptions.map((e) {
                          final isCustom = e == 'Custom' && reminderAt != null;
                          final label = isCustom
                              ? 'Custom (${humanDue(reminderAt!)} · ${TimeOfDay.fromDateTime(reminderAt!).format(context)})'
                              : e;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList();
                      },

                      // 👇 下拉清單中的每一列（同樣把 Custom 顯示為含括號）
                      items: reminderOptions.map((e) {
                        final isCustom = e == 'Custom' && reminderAt != null;
                        final label = isCustom
                            ? 'Custom (${humanDue(reminderAt!)} · ${TimeOfDay.fromDateTime(reminderAt!).format(context)})'
                            : e;
                        return DropdownMenuItem(value: e, child: Text(label));
                      }).toList(),
                      onChanged: (v) async {
                        if (v == null) return;

                        if (v == 'Custom') {
                          // 先讓使用者挑日期
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2100),
                            initialDate: due,
                          );
                          if (d == null) return; // 取消就不改 state

                          // 再挑時間
                          final t = await pickTime(context, TimeOfDay.now());
                          if (t == null) return; // 取消就不改 state

                          final picked = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t.hour,
                            t.minute,
                          );

                          setState(() {
                            reminderType = 'Custom';
                            reminderAt = picked;
                          });
                          return;
                        }

                        // 其他固定選項
                        DateTime? at;
                        if (v == '1 day before (9am)') {
                          at = DateTime(due.year, due.month, due.day - 1, 9);
                        } else if (v == 'Due morning (9am)') {
                          at = DateTime(due.year, due.month, due.day, 9);
                        } else if (v == '3 hours before') {
                          at = due.subtract(const Duration(hours: 3));
                        } else {
                          at = null;
                        }

                        setState(() {
                          reminderType = v;
                          reminderAt = at;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Color（標題對齊 + 一整條色彩圓圈，直接點選，不跳視窗）
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            _colorStrip(
              options: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple,
                Colors.pink,
                Colors.brown,
                Colors.grey,
              ],
              selected: color,
              onChanged: (c) => setState(() => color = c),
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: () {
                      // ✅ 直接刪除（不保留）
                      app.removeHomework(widget.existing!['id']);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF), // 修改底色
                  ),
                  onPressed: () {
                    if (title.text.trim().isEmpty) {
                      setState(() => titleError = true);
                      return;
                    }

                    final data = {
                      'title': title.text,
                      'content': content.text,
                      'due': due.toIso8601String(),
                      'reminderType': reminderType,
                      'reminderAt': reminderAt?.toIso8601String(),
                      'color': color.value,
                      'id': widget.existing?['id'],
                      'doneAt': widget.existing?['doneAt'],
                    };

                    if (widget.existing == null) {
                      app.addHomework(data);
                    } else {
                      app.updateHomework(data);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
