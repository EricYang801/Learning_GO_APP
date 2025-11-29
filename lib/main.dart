import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';

// 拆分的 State 類
import 'features/home/state/todo_state.dart';
import 'features/home/state/homework_state.dart';
import 'features/home/state/timer_state.dart';
import 'features/home/state/media_state.dart';
import 'features/home/state/announcement_state.dart';
import 'features/voice/state/voice_state.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服務
  await NotificationService().init();

  // 建立所有 State 實例
  final todoState = TodoState();
  final homeworkState = HomeworkState();
  final timerState = TimerState();
  final mediaState = MediaState();
  final announcementState = AnnouncementState();
  final voiceState = VoiceState();

  // 載入所有資料
  await Future.wait([
    todoState.load(),
    homeworkState.load(),
    timerState.load(),
    mediaState.load(),
    announcementState.load(),
  ]);

  // 安排每日檢查
  await announcementState.scheduleDailyMidnightCheck();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => todoState),
        ChangeNotifierProvider(create: (_) => homeworkState),
        ChangeNotifierProvider(create: (_) => timerState),
        ChangeNotifierProvider(create: (_) => mediaState),
        ChangeNotifierProvider(create: (_) => announcementState),
        ChangeNotifierProvider(create: (_) => voiceState),
      ],
      child: const LearningGOApp(),
    ),
  );
}
