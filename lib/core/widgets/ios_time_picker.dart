// lib/widgets/ios_time_picker.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const Color _actionBlue = Color(0xFF007AFF); // iOS-style blue

/// 判斷是否用 Cupertino 風格（iOS / macOS，且非 Web）
bool get _isCupertinoPlatform {
  final p = defaultTargetPlatform;
  return !kIsWeb && (p == TargetPlatform.iOS || p == TargetPlatform.macOS);
}

/// 置中「提示匡」（純白卡片）
/// - 完全自訂白底容器，避免 CupertinoAlertDialog 造成的灰底/透明
Future<T?> _showCupertinoCenterDialog<T>({
  required BuildContext context,
  required Widget content,
  List<Widget>? actions,
  String? title,
  double? preferredWidth, // ⬅️ 新增：可指定建議寬度
}) {
  return showCupertinoDialog<T>(
    context: context,
    builder: (ctx) {
      // 以 LayoutBuilder 做自適應寬度
      return LayoutBuilder(
        builder: (_, constraints) {
          final double maxW = constraints.maxWidth;
          // 針對 h:m:s 可能太擠；若有指定就用指定寬度，否則預設 340
          final double dialogW = (preferredWidth ?? 340).clamp(
            280.0,
            maxW - 24,
          );

          return Center(
            child: Container(
              width: dialogW,
              decoration: BoxDecoration(
                color: Colors.white, // ✨ 整個提示匡純白
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center, // 垂直置中
                crossAxisAlignment: CrossAxisAlignment.center, // 水平置中
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      // 關閉任何文字選取/互動，並移除底線
                      child: SelectionContainer.disabled(
                        child: IgnorePointer(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  // 內容：再包一層白底，確保滾輪後方為白
                  Container(color: Colors.white, child: content),
                  const SizedBox(height: 12),
                  // 底部按鈕列（左右各半，白底）
                  Row(
                    children:
                        (actions ??
                        [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _actionBlue, // 固定藍色
                              ),
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _actionBlue, // 固定藍色
                              ),
                            ),
                          ),
                        ]),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// 跨平台時間選擇器（置中提示匡版本）
Future<TimeOfDay?> pickTime(
  BuildContext context,
  TimeOfDay initial, {
  bool use24h = true,
  String title = 'Select time',
  String cancelText = 'Cancel',
  String doneText = 'Done',
}) async {
  if (!_isCupertinoPlatform) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final themed = Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.white,
              hourMinuteColor: Colors.white,
              dayPeriodColor: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24h),
          child: themed,
        );
      },
    );
  }

  TimeOfDay temp = initial;

  return _showCupertinoCenterDialog<TimeOfDay>(
    context: context,
    title: title,
    content: SizedBox(
      height: 180,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        use24hFormat: use24h,
        initialDateTime: DateTime(0, 1, 1, initial.hour, initial.minute),
        onDateTimeChanged: (dt) {
          temp = TimeOfDay(hour: dt.hour, minute: dt.minute);
        },
      ),
    ),
    actions: [
      CupertinoButton(
        onPressed: () => Navigator.of(context).pop(null),
        child: Text(
          cancelText,
          style: const TextStyle(
            color: _actionBlue, // 固定藍色
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const Spacer(),
      CupertinoButton(
        onPressed: () => Navigator.of(context).pop(temp),
        child: Text(
          doneText,
          style: const TextStyle(
            color: _actionBlue, // 固定藍色
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// 跨平台「日期選擇器」（置中提示匡版本）
Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Select date',
  String cancelText = 'Cancel',
  String doneText = 'Done',
}) async {
  final now = DateTime.now();
  final init = initialDate ?? DateTime(now.year, now.month, now.day);
  final first = firstDate ?? DateTime(now.year - 50);
  final last = lastDate ?? DateTime(now.year + 50);

  if (!_isCupertinoPlatform) {
    return showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
  }

  DateTime temp = init;

  return _showCupertinoCenterDialog<DateTime>(
    context: context,
    title: title,
    content: SizedBox(
      height: 220,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: init,
        minimumDate: first,
        maximumDate: last,
        onDateTimeChanged: (dt) => temp = DateTime(dt.year, dt.month, dt.day),
      ),
    ),
    actions: [
      CupertinoButton(
        onPressed: () => Navigator.of(context).pop(null),
        child: Text(
          cancelText,
          style: const TextStyle(
            color: _actionBlue, // 固定藍色
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const Spacer(),
      CupertinoButton(
        onPressed: () => Navigator.of(context).pop(temp),
        child: Text(
          doneText,
          style: const TextStyle(
            color: _actionBlue, // 固定藍色
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// 跨平台「倒數計時/Duration 選擇器」（置中提示匡版本）
Future<Duration?> pickDuration(
  BuildContext context, {
  Duration initial = const Duration(minutes: 5),
  String title = 'Timer',
  String cancelText = 'Cancel',
  String doneText = 'Done',
  CupertinoTimerPickerMode mode = CupertinoTimerPickerMode.hm, // hh:mm
}) async {
  Duration temp = initial;

  final picker = SizedBox(
    height: 180,
    child: CupertinoTimerPicker(
      mode: mode,
      initialTimerDuration: initial,
      onTimerDurationChanged: (d) => temp = d,
    ),
  );

  if (_isCupertinoPlatform) {
    return _showCupertinoCenterDialog<Duration>(
      context: context,
      title: title,
      content: picker,
      actions: [
        CupertinoButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            cancelText,
            style: const TextStyle(
              color: _actionBlue, // 固定藍色
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        CupertinoButton(
          onPressed: () => Navigator.of(context).pop(temp),
          child: Text(
            doneText,
            style: const TextStyle(
              color: _actionBlue, // 固定藍色
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  } else {
    return showDialog<Duration>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: picker,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                cancelText,
                style: const TextStyle(
                  color: _actionBlue, // 固定藍色
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(temp),
              child: Text(
                doneText,
                style: const TextStyle(
                  color: _actionBlue, // 固定藍色
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 專用：學習目標時間選擇（hh:mm 的滾輪）
Future<Duration?> pickStudyGoalDuration(
  BuildContext context, {
  Duration initial = const Duration(hours: 1),
  String title = "Set today's study goal",
  String cancelText = 'Cancel',
  String doneText = 'Save',
}) {
  return pickDuration(
    context,
    initial: initial,
    title: title,
    cancelText: cancelText,
    doneText: doneText,
    mode: CupertinoTimerPickerMode.hm, // hh:mm
  );
}

/// 內嵌的 Duration 滾輪（跨平台皆可用）
Widget inlineDurationPicker({
  required Duration initial,
  required ValueChanged<Duration> onChanged,
  CupertinoTimerPickerMode mode = CupertinoTimerPickerMode.hm,
  int minuteInterval = 1,
  double height = 180,
}) {
  Duration temp = initial;
  return SizedBox(
    height: height,
    child: CupertinoTimerPicker(
      mode: mode,
      initialTimerDuration: initial,
      minuteInterval: minuteInterval,
      onTimerDurationChanged: (d) {
        temp = d;
        onChanged(temp);
      },
    ),
  );
}

// 選擇倒數時間（含 時/分/秒），白底置中對話框
Future<Duration?> pickCountdownHMS(
  BuildContext context, {
  Duration initial = const Duration(minutes: 25),
  String title = 'Set countdown',
  String cancelText = 'Cancel',
  String doneText = 'Done',
  int minuteInterval = 1,
  int secondInterval = 1,
}) async {
  Duration temp = initial;

  final picker = SizedBox(
    height: 216, // ⬆️ 稍微增高，視覺更舒服
    child: CupertinoTimerPicker(
      mode: CupertinoTimerPickerMode.hms, // ⬅️ 時/分/秒
      initialTimerDuration: initial,
      minuteInterval: minuteInterval,
      secondInterval: secondInterval,
      onTimerDurationChanged: (d) => temp = d,
    ),
  );

  // iOS / macOS：使用自訂白底置中提示匡（加寬 + 內邊距）
  if (_isCupertinoPlatform) {
    return _showCupertinoCenterDialog<Duration>(
      context: context,
      title: title,
      preferredWidth: 372, // ⬅️ 加寬，避免 "hours" 被截到
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6), // ⬅️ 內容左右留白
        child: picker,
      ),
      actions: [
        CupertinoButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            cancelText,
            style: const TextStyle(
              color: _actionBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        CupertinoButton(
          onPressed: () => Navigator.of(context).pop(temp),
          child: Text(
            doneText,
            style: const TextStyle(
              color: _actionBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // 其他平台：依然用白底 AlertDialog 包同一顆 CupertinoTimerPicker
  return showDialog<Duration>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6), // 同步左右留白
          child: picker,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: _actionBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(temp),
            child: Text(
              doneText,
              style: const TextStyle(
                color: _actionBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}
