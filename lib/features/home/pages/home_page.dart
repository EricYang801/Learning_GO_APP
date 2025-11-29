import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../state/todo_state.dart';
import '../state/homework_state.dart';
import '../state/timer_state.dart';
import '../widgets/section_card.dart';
import '../widgets/todo_homework_sheets.dart';
import '../widgets/timer_sheets.dart';
import '../widgets/ring_progress.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _completeTimer;

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoState = context.watch<TodoState>();
    final hwState = context.watch<HomeworkState>();
    final timerState = context.watch<TimerState>();

    final done =
        todoState.todos.where((t) => t.doneAt != null).length +
        hwState.homeworks.where((h) => h.doneAt != null).length;
    final total = todoState.todos.length + hwState.homeworks.length;

    final today = timerState.todaySeconds;
    final goal = timerState.todayGoalSeconds;
    final ratio = (goal == null || goal == 0)
        ? 0.0
        : (today / goal).clamp(0.0, 1.0);
    final goalReached = goal != null && today >= goal;
    final center = goal == null
        ? 'No goal'
        : (today >= goal
              ? '+${hhmm(today - goal)}'
              : '-${hhmm((goal - today).clamp(0, 999999))}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('LearningGO'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1) Daily Task
          SectionCard(
            title: 'Daily Task',
            tint: AppColors.softBlue,
            trailing: Text(
              '$done / $total',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
          ),

          // 2) To-Do List
          Expanded(
            child: SectionCard(
              title: 'To-Do List',
              tint: AppColors.softCyan,
              expandChild: true,
              trailing: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddTodoSheet(),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.add_circle_outline, size: 22),
                ),
              ),
              child: Builder(
                builder: (_) {
                  final todos = todoState.visibleTodos;
                  if (todos.isEmpty) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No To-Do',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: todos.length,
                    itemBuilder: (_, i) {
                      final t = todos[i];
                      bool checked = false;
                      return StatefulBuilder(
                        builder: (ctx, setLocal) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: 12,
                            leading: Checkbox(
                              value: checked,
                              onChanged: (v) {
                                setLocal(() => checked = v ?? false);
                                _completeTimer?.cancel();
                                if (checked) {
                                  _completeTimer = Timer(
                                    const Duration(seconds: 3),
                                    () {
                                      todoState.complete(t.id);
                                    },
                                  );
                                }
                              },
                              shape: const CircleBorder(),
                              activeColor: AppColors.accent,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),

                            title: Text(
                              t.title,
                              style: const TextStyle(fontSize: 16),
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => AddTodoSheet(existing: t),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 3) Homework
          Expanded(
            child: SectionCard(
              title: 'Homework',
              tint: AppColors.softOrange,
              expandChild: true,
              trailing: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddHomeworkSheet(),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.add_circle_outline, size: 22),
                ),
              ),
              child: Builder(
                builder: (_) {
                  final homeworks = hwState.visibleHomeworks;
                  if (homeworks.isEmpty) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No Homework',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: homeworks.length,
                    itemBuilder: (_, i) {
                      final h = homeworks[i];
                      bool checked = false;
                      return StatefulBuilder(
                        builder: (ctx, setLocal) {
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
                                      int.tryParse(h.color ?? '', radix: 16) ??
                                          0xFFFFA000,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                            title: Text(
                              h.title,
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: Checkbox(
                              value: checked,
                              onChanged: (v) {
                                setLocal(() => checked = v ?? false);
                                _completeTimer?.cancel();
                                if (checked) {
                                  _completeTimer = Timer(
                                    const Duration(seconds: 3),
                                    () {
                                      hwState.complete(h.id);
                                    },
                                  );
                                }
                              },
                              activeColor: AppColors.accent,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => AddHomeworkSheet(existing: h),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 4) Study Timer
          SectionCard(
            title: 'Study Timer',
            tint: AppColors.softGray,
            trailing: Text(
              hhmm(today),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RingProgress(
                  ratio: ratio,
                  goalReached: goalReached,
                  centerText: center,
                  dimmed: goal == null,
                ),
                const SizedBox(width: 75),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const SetGoalSheet(),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Set Goal'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const TimerModeSheet(),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Start Study'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
