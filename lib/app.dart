import 'package:flutter/material.dart';
import 'features/home/pages/home_page.dart';
import 'features/voice/pages/voice_page.dart';
import 'features/image_tool/pages/image_tool_page.dart';
import 'features/settings/pages/settings_page.dart';

class LearningGOApp extends StatefulWidget {
  const LearningGOApp({super.key});
  @override
  State<LearningGOApp> createState() => _LearningGOAppState();
}

class _LearningGOAppState extends State<LearningGOApp> {
  int _index = 0;

  // 追蹤哪些頁面已經被訪問過（延遲載入機制）
  // 首頁預設載入，其他頁面只有在第一次切換時才建立
  final Set<int> _loadedPages = {0};

  /// 根據 index 建立對應的頁面 Widget
  /// 只有在 _loadedPages 包含該 index 時才返回真正的頁面
  Widget _buildPage(int index) {
    // 如果該頁面尚未被訪問過，返回空的佔位 Widget
    if (!_loadedPages.contains(index)) {
      return const SizedBox.shrink();
    }

    // 返回對應的頁面
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const VoicePage();
      case 2:
        return const ImageToolPage();
      case 3:
        return const SettingsPage();
      default:
        return const HomePage();
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      // 標記該頁面為已載入（如果是第一次訪問）
      _loadedPages.add(index);
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearningGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // ✅ body：白底
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white, // ✅ AppBar 白底
          elevation: 0,
          foregroundColor: Colors.black, // ✅ 文字與icon黑色
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),

        // 日期選擇器統一樣式（影響 showDatePicker）
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),

          // 一般日期
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            if (states.contains(WidgetState.disabled)) return Colors.black26;
            return Colors.black87;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF007AFF);
            }
            return Colors.transparent;
          }),

          // 「今天」：未選中是淡藍底；選中時改成和一般選中一致（藍底白字）
          todayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white; // 選中「今天」文字色
            }
            return const Color(0xFF007AFF); // 未選中「今天」文字色
          }),
          todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF007AFF); // 選中「今天」底色
            }
            return const Color(0xFF007AFF).withValues(alpha: 0.15); // 未選中「今天」底色
          }),
          // 如果不想「今天」在選中時還有外框，可改成 BorderSide.none
          // todayBorder: BorderSide.none,
          todayBorder: const BorderSide(color: Color(0xFF007AFF)),
        ),

        // 讓右下角按鈕（確定/取消）變藍、字體大小 18
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF007AFF),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 當切換成「輸入模式」時，輸入框與游標顏色統一藍色
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.grey), // 未浮起時的標籤色
          floatingLabelStyle: TextStyle(color: Colors.black), // 浮起時的標籤色（聚焦/有值）
          hintStyle: TextStyle(color: Colors.grey), // 只有真的看到 hint 才會用到

          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0x33007AFF),
          selectionHandleColor: Color(0xFF007AFF),
        ),

        timePickerTheme: const TimePickerThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      home: Scaffold(
        // 使用 IndexedStack 保持已訪問頁面的狀態
        // 配合 _loadedPages 實現延遲載入
        body: IndexedStack(
          index: _index,
          children: [
            _buildPage(0),
            _buildPage(1),
            _buildPage(2),
            _buildPage(3),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white, // ✅ 底部白底
          indicatorColor: const Color(0xFFCCE4FF),
          surfaceTintColor: Colors.transparent, // 防止Material3陰影
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.keyboard_voice_outlined),
              selectedIcon: Icon(Icons.keyboard_voice),
              label: 'Voice to Text',
            ),
            NavigationDestination(
              icon: Icon(Icons.image_outlined),
              selectedIcon: Icon(Icons.image),
              label: 'Image Tool',
            ),
            NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined),
              selectedIcon: Icon(Icons.insert_chart),
              label: 'Charts',
            ),
          ],
        ),
      ),
    );
  }
}
