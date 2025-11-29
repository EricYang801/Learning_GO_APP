import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/ios_time_picker.dart';

class SetGoalSheet extends StatefulWidget {
  const SetGoalSheet({super.key});
  @override
  State<SetGoalSheet> createState() => _SetGoalSheetState();
}

class _SetGoalSheetState extends State<SetGoalSheet> {
  late Duration _goal; // ✅ 用 late，等 initState 設定

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    // ✅ 讀取上次設定的目標秒數，沒有就用 1 小時
    final last = app.todayGoalSeconds; // int? (秒)
    _goal = Duration(seconds: (last ?? 3600).clamp(0, 24 * 3600));
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
            ),
            onPressed: () {
              app.setGoalSeconds(_goal.inSeconds); // ✅ 存回去
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
    final app = context.read<AppState>();
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
          // ───────────────── Header：左 Title、右 Segmented pill ─────────────────
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
              if (running) return; // 計時途中不可更改

              final app = context.read<AppState>();
              // 以「上次使用者設定的時間」為初始；若沒有就用目前 countdown
              final initial = Duration(
                seconds: (app.lastCountdownSeconds ?? countdown).clamp(
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
                  // ⬇️ 視為「新的使用者設定時間」，覆蓋基準
                  app.lastCountdownSeconds = countdown;
                  // 不在此時紀錄任何已經過時間 → 自然「不會累加」
                  // 同時因為 countdown 可能從 0 變成 >0，會讓 Start 能按
                });
              }
            },
            child: Text(
              _hhmmss(showSeconds),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          // ✅ 三個固定等寬的控制按鈕
          SizedBox(
            height: 48, // 統一高度
            child: Row(
              children: [
                // ✅ Start / Pause 按鈕（綠底 ↔ 紅底）
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: running
                          ? Colors
                                .red // 紅色（暫停）
                          : Colors.green, // 綠色（開始）
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
                              app.startStudySession();
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

                // ✅ Reset 按鈕（藍框藍字）
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF007AFF),
                      side: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 1.5,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      // 🔹 停止計時器
                      _ticker?.cancel();
                      setState(() {
                        running = false; // 左邊按鈕回到 Start

                        if (mode == 'stopwatch') {
                          elapsed = 0;
                        } else {
                          countdown = app.lastCountdownSeconds ?? 1500;
                        }
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),

                const SizedBox(width: 8),

                // ✅ Save 按鈕（淺藍底 + 藍字）
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD6E6FF), // 淺藍底
                      foregroundColor: const Color(0xFF007AFF), // 藍色文字
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
                                : ((app.lastCountdownSeconds ?? 1500) -
                                          countdown)
                                      .clamp(0, 24 * 3600);

                            // ⬇️ 取整到分鐘（向下取整）
                            final gained = ((raw + 30) ~/ 60) * 60; // 四捨五入到分鐘

                            app.endStudySession();

                            if (gained >= 60) app.addTodaySeconds(gained);
                            if (mode == 'countdown') {
                              app.lastCountdownSeconds =
                                  countdown; // 你原本的行為，依需求保留
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
