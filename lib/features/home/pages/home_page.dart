import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/todo.dart';
import '../../../core/models/homework.dart';
import '../../../core/utils/format.dart';
import '../state/todo_state.dart';
import '../state/homework_state.dart';
import '../state/timer_state.dart';
import '../widgets/section_card.dart';
import '../widgets/todo_homework_sheets.dart';
import '../widgets/timer_sheets.dart';
import '../widgets/ring_progress.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/homework_list_item.dart';
import 'notifications_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          // 1) Daily Task - 使用 Selector2 只監聽完成數量
          const _DailyTaskSection(),

          // 2) To-Do List - 使用 Selector 只監聽 visibleTodos
          const Expanded(child: _TodoListSection()),

          // 3) Homework - 使用 Selector 只監聽 visibleHomeworks
          const Expanded(child: _HomeworkListSection()),

          // 4) Study Timer - 使用 Selector 只監聽時間相關資料
          const _StudyTimerSection(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// Daily Task 區塊 - 只在 done/total 變化時重建
class _DailyTaskSection extends StatelessWidget {
  const _DailyTaskSection();

  @override
  Widget build(BuildContext context) {
    return Selector2<TodoState, HomeworkState, ({int done, int total})>(
      selector: (_, todoState, hwState) {
        final done =
            todoState.todos.where((t) => t.doneAt != null).length +
            hwState.homeworks.where((h) => h.doneAt != null).length;
        final total = todoState.todos.length + hwState.homeworks.length;
        return (done: done, total: total);
      },
      builder: (context, data, _) {
        return SectionCard(
          title: 'Daily Task',
          tint: AppColors.softBlue,
          trailing: Text(
            '${data.done} / ${data.total}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: LinearProgressIndicator(
            value: data.total == 0 ? 0 : data.done / data.total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Colors.blue),
          ),
        );
      },
    );
  }
}

/// To-Do List 區塊 - 只在 visibleTodos 變化時重建
class _TodoListSection extends StatelessWidget {
  const _TodoListSection();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
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
      child: Selector<TodoState, List<Todo>>(
        selector: (_, state) => state.visibleTodos,
        builder: (context, todos, _) {
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
            itemBuilder: (context, i) {
              final t = todos[i];
              return TodoListItem(
                key: ValueKey(t.id),
                todo: t,
                onComplete: () => context.read<TodoState>().complete(t.id),
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
      ),
    );
  }
}

/// Homework 區塊 - 只在 visibleHomeworks 變化時重建
class _HomeworkListSection extends StatelessWidget {
  const _HomeworkListSection();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
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
      child: Selector<HomeworkState, List<Homework>>(
        selector: (_, state) => state.visibleHomeworks,
        builder: (context, homeworks, _) {
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
            itemBuilder: (context, i) {
              final h = homeworks[i];
              return HomeworkListItem(
                key: ValueKey(h.id),
                homework: h,
                onComplete: () => context.read<HomeworkState>().complete(h.id),
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
      ),
    );
  }
}

/// Study Timer 區塊 - 只在時間相關資料變化時重建
class _StudyTimerSection extends StatelessWidget {
  const _StudyTimerSection();

  @override
  Widget build(BuildContext context) {
    return Selector<TimerState, ({int today, int? goal})>(
      selector: (_, state) =>
          (today: state.todaySeconds, goal: state.todayGoalSeconds),
      builder: (context, data, _) {
        final today = data.today;
        final goal = data.goal;
        final ratio = (goal == null || goal == 0)
            ? 0.0
            : (today / goal).clamp(0.0, 1.0);
        final goalReached = goal != null && today >= goal;
        final center = goal == null
            ? 'No goal'
            : (today >= goal
                  ? '+${hhmm(today - goal)}'
                  : '-${hhmm((goal - today).clamp(0, 999999))}');

        return SectionCard(
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
                        side: const BorderSide(color: Colors.green, width: 1.5),
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
        );
      },
    );
  }
}
