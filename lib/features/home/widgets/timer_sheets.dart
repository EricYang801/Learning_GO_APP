import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_time_picker.dart';
import '../state/timer_state.dart';

class SetGoalSheet extends StatefulWidget {
  const SetGoalSheet({super.key});
  @override
  State<SetGoalSheet> createState() => _SetGoalSheetState();
}

class _SetGoalSheetState extends State<SetGoalSheet> {
  late Duration _goal;

  @override
  void initState() {
    super.initState();
    final timer = context.read<TimerState>();
    final last = timer.todayGoalSeconds;
    _goal = Duration(seconds: (last ?? 3600).clamp(0, 24 * 3600));
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.read<TimerState>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Set today's study goal",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          inlineDurationPicker(
            initial: _goal,
            minuteInterval: 5,
            onChanged: (d) => setState(() => _goal = d),
          ),

          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              timer.setGoalSeconds(_goal.inSeconds);
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class NumberPicker extends StatelessWidget {
  final int value;
  final String label;
  final int max;
  final int step;
  final void Function(int) onChanged;
  const NumberPicker({
    super.key,
    required this.value,
    required this.label,
    this.max = 23,
    this.step = 1,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => onChanged((value - step).clamp(0, max)),
          icon: const Icon(Icons.remove),
        ),
        Text('$value$label', style: const TextStyle(fontSize: 18)),
        IconButton(
          onPressed: () => onChanged((value + step).clamp(0, max)),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class TimerModeSheet extends StatefulWidget {
  const TimerModeSheet({super.key});
  @override
  State<TimerModeSheet> createState() => _TimerModeSheetState();
}

class _TimerModeSheetState extends State<TimerModeSheet> {
  String mode = 'stopwatch';
  int countdown = 1500; // 25min
  int elapsed = 0;
  Timer? _ticker;
  bool running = false;

  String _hhmmss(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  void _tick() {
    setState(() {
      if (mode == 'stopwatch') {
        elapsed += 1;
      } else {
        if (countdown > 0) countdown -= 1;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.read<TimerState>();
    final showSeconds = mode == 'stopwatch' ? elapsed : countdown;
    final bool canStart = !(mode == 'countdown' && countdown <= 0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header：左 Title、右 Segmented pill
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Study Timer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ModeSwitch(
                isStopwatch: mode == 'stopwatch',
                onChanged: (v) =>
                    setState(() => mode = v ? 'stopwatch' : 'countdown'),
              ),
            ],
          ),

          const SizedBox(height: 30),

          GestureDetector(
            onTap: () async {
              if (mode != 'countdown') return;
              if (running) return;

              final initial = Duration(
                seconds: (timer.lastCountdownSeconds ?? countdown).clamp(
                  0,
                  24 * 3600,
                ),
              );

              final picked = await pickCountdownHMS(
                context,
                initial: initial,
                title: 'Set countdown',
                minuteInterval: 1,
                secondInterval: 1,
              );

              if (picked != null) {
                setState(() {
                  countdown = picked.inSeconds;
                  timer.setLastCountdownSeconds(countdown);
                });
              }
            },
            child: Text(
              _hhmmss(showSeconds),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          // 三個固定等寬的控制按鈕
          SizedBox(
            height: 48,
            child: Row(
              children: [
                // Start / Pause 按鈕
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: running ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: !canStart
                        ? null
                        : () {
                            if (!running) {
                              timer.startStudySession();
                              _ticker = Timer.periodic(
                                const Duration(seconds: 1),
                                (_) => _tick(),
                              );
                            }
                            setState(() => running = !running);
                            if (!running) _ticker?.cancel();
                          },
                    child: Text(running ? 'Pause' : 'Start'),
                  ),
                ),

                const SizedBox(width: 8),

                // Reset 按鈕
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(
                        color: AppColors.accent,
                        width: 1.5,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      _ticker?.cancel();
                      setState(() {
                        running = false;

                        if (mode == 'stopwatch') {
                          elapsed = 0;
                        } else {
                          countdown = timer.lastCountdownSeconds ?? 1500;
                        }
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),

                const SizedBox(width: 8),

                // Save 按鈕
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD6E6FF),
                      foregroundColor: AppColors.accent,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: running
                        ? null
                        : () {
                            final raw = mode == 'stopwatch'
                                ? elapsed
                                : ((timer.lastCountdownSeconds ?? 1500) -
                                          countdown)
                                      .clamp(0, 24 * 3600);

                            final gained = ((raw + 30) ~/ 60) * 60;

                            timer.endStudySession();

                            if (gained >= 60) timer.addTodaySeconds(gained);
                            if (mode == 'countdown') {
                              timer.setLastCountdownSeconds(countdown);
                            }
                            Navigator.pop(context);
                          },

                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// iOS 風格滑動藥丸切換（Stopwatch / Countdown）
class _ModeSwitch extends StatelessWidget {
  final bool isStopwatch;
  final ValueChanged<bool> onChanged;

  const _ModeSwitch({required this.isStopwatch, required this.onChanged});

  static const _blue = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 200,
      padding: const EdgeInsets.all(3), // ✅ 留一點內邊距讓文字不貼邊
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7), // 淺灰背景（整個大藥丸）
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔵 藍色滑動小藥丸背景
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: isStopwatch
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5, // 小藥丸佔整體一半寬
              child: Container(
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),

          // ⏱ 兩側文字（保持可點擊）
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isStopwatch ? Colors.white : Colors.black87,
                      ),
                      child: const Text('Stopwatch'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isStopwatch ? Colors.black87 : Colors.white,
                      ),
                      child: const Text('Countdown'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
