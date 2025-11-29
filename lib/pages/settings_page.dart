import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_colors.dart';
import '../widgets/section_card.dart';
import 'package:fl_chart/fl_chart.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showToday = true;
  bool _showWeek = true;
  bool _showMonth = true;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    return Scaffold(
      endDrawer: _buildRightMenu(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Charts'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_showToday) _buildTodayTimelineChart(app),
          if (_showWeek) _buildWeekChart(app),
          if (_showMonth) _buildMonthChart(app),
        ],
      ),
    );
  }

  // 右側選單
  Widget _buildRightMenu(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Drawer(
      width: width * 0.6,
      backgroundColor: Colors.white,
      elevation: 16,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Charts Menu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Today's Study (Timeline)"),
              value: _showToday,
              onChanged: (v) => setState(() => _showToday = v),
            ),
            SwitchListTile(
              title: const Text("This Week's Study"),
              value: _showWeek,
              onChanged: (v) => setState(() => _showWeek = v),
            ),
            SwitchListTile(
              title: const Text("This Month's Study"),
              value: _showMonth,
              onChanged: (v) => setState(() => _showMonth = v),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Helpers
  // =========================================================

  String _dateKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  double _calcDiffPercent(int current, int prev) {
    if (prev == 0) return current == 0 ? 0 : 100;
    return (current - prev) / prev * 100;
  }

  int _totalSecondsForDateFromSeconds(AppState app, DateTime date) {
    return app.todaySeconds(date);
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  int _nowMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  double _maxMinutes(List<double> vals) {
    double m = 0;
    for (final v in vals) {
      if (v > m) m = v;
    }
    return m;
  }

  // =========================================================
  // 今日 Timeline（中心現在時間 ± 3 小時）
  // =========================================================
  Widget _buildTodayTimelineChart(AppState app) {
    final now = DateTime.now();
    final todayStr = _dateKey(now);

    List<Map<String, dynamic>> sessions = [];

    for (final rec in app.timerDaily) {
      if (rec['date'] == todayStr && rec['sessions'] is List) {
        sessions = rec['sessions'].cast<Map<String, dynamic>>();
        break;
      }
    }

    final nowMins = _nowMinutes();
    final todaySecs = _totalSecondsForDateFromSeconds(app, now);
    final yesterdaySecs =
        _totalSecondsForDateFromSeconds(app, now.subtract(const Duration(days: 1)));
    final diffP = _calcDiffPercent(todaySecs, yesterdaySecs);

    return SectionCard(
      title: "Today's Study",
      tint: AppColors.softGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),

          // ⭐⭐⭐ Timeline 一定顯示 ⭐⭐⭐
          SizedBox(
            height: 50,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _DayTimelinePainter(
                sessions: sessions,
                centerMinutes: nowMins,
              ),
            ),
          ),
          _buildTimelineLabels(nowMins),
          const SizedBox(height: 12),

          // 數字 + 百分比
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bigNumber(todaySecs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  "${diffP >= 0 ? '+' : ''}${diffP.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 13,
                    color: diffP >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Timeline Labels
  Widget _buildTimelineLabels(int centerMinutes) {
    int clamp(int m) =>
        m < 0 ? 0 : (m > 1439 ? 1439 : m);

    String fmt(int m) =>
        "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";

    final leftMost = clamp(centerMinutes - 180);
    final leftMid = clamp(centerMinutes - 90);
    final center = clamp(centerMinutes);
    final rightMid = clamp(centerMinutes + 90);
    final rightMost = clamp(centerMinutes + 180);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fmt(leftMost), style: const TextStyle(fontSize: 11)),
        Text(fmt(leftMid), style: const TextStyle(fontSize: 11)),
        Text(fmt(center), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text(fmt(rightMid), style: const TextStyle(fontSize: 11)),
        Text(fmt(rightMost), style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // =========================================================
  // 週 + 月 長條圖（不變）
  // =========================================================

  // 🔹 大字數字顯示：分鐘 / 小時 自動切換
  Widget _bigNumber(int seconds) {
    final mins = seconds / 60.0;
    if (mins < 60) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: mins.toStringAsFixed(0),
              style: const TextStyle(
                  fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: " min",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      );
    } else {
      final hrs = mins / 60.0;
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: hrs.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: " hr",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      );
    }
  }

  // =========================================================
  // Weekly Chart（不變）
  // =========================================================
  Widget _buildWeekChart(AppState app) {
    final now = DateTime.now();
    const weekdayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final rawMinutes = <double>[];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      rawMinutes.add(app.todaySeconds(d) / 60.0);
      labels.add(weekdayLabel[d.weekday - 1]);
    }

    final thisWeekSecs = [
      for (int i = 0; i < 7; i++) app.todaySeconds(now.subtract(Duration(days: i)))
    ].reduce((a, b) => a + b);

    final lastWeekSecs = [
      for (int i = 7; i < 14; i++) app.todaySeconds(now.subtract(Duration(days: i)))
    ].reduce((a, b) => a + b);

    final diffP = _calcDiffPercent(thisWeekSecs, lastWeekSecs);

    final maxMin = _maxMinutes(rawMinutes);
    final bool useHours = maxMin >= 60;

    late List<double> ys;
    late double maxY;
    late double interval;

    if (!useHours) {
      ys = rawMinutes;
      if (maxMin <= 10) {
        maxY = 10;
        interval = 2;
      } else if (maxMin <= 20) {
        maxY = 20;
        interval = 5;
      } else {
        maxY = 60;
        interval = 10;
      }
    } else {
      ys = rawMinutes.map((m) => m / 60.0).toList();
      maxY = (maxMin / 60).ceilToDouble();
      interval = 1;
    }

    return SectionCard(
      title: "This Week's Study",
      tint: AppColors.softGray,
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),

          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: ys[i],
                        width: 14,
                        color: Colors.green,
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 38,
                      showTitles: true,
                      interval: interval,
                      getTitlesWidget: (v, meta) => Text(
                          useHours ? "${v.toInt()}h" : "${v.toInt()}m",
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        int i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i],
                            style: const TextStyle(fontSize: 11));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bigNumber(thisWeekSecs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  "${diffP >= 0 ? '+' : ''}${diffP.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 13,
                    color: diffP >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 每月圖表（不變）
  // =========================================================
  Widget _buildMonthChart(AppState app) {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;
    final days = DateTime(y, m + 1, 0).day;

    final mins = <double>[];
    final labels = <String>[];

    for (int d = 1; d <= days; d++) {
      mins.add(app.todaySeconds(DateTime(y, m, d)) / 60.0);
      labels.add(d.toString());
    }

    final thisMonthSecs = [
      for (int d = 1; d <= days; d++)
        app.todaySeconds(DateTime(y, m, d))
    ].reduce((a, b) => a + b);

    // 上個月
    int py = y, pm = m - 1;
    if (pm == 0) {
      pm = 12;
      py--;
    }
    final pDays = DateTime(py, pm + 1, 0).day;

    final lastMonthSecs = [
      for (int d = 1; d <= pDays; d++)
        app.todaySeconds(DateTime(py, pm, d))
    ].reduce((a, b) => a + b);

    final diffP = _calcDiffPercent(thisMonthSecs, lastMonthSecs);

    final maxMin = _maxMinutes(mins);
    final useHours = maxMin >= 60;

    late List<double> ys;
    late double maxY;
    late double interval;

    if (!useHours) {
      ys = mins;
      if (maxMin <= 10) {
        maxY = 10;
        interval = 2;
      } else if (maxMin <= 20) {
        maxY = 20;
        interval = 5;
      } else {
        maxY = 60;
        interval = 10;
      }
    } else {
      ys = mins.map((e) => e / 60.0).toList();
      maxY = (maxMin / 60).ceilToDouble();
      interval = 1;
    }

    return SectionCard(
      title: "This Month's Study",
      tint: AppColors.softGray,
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),

          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                barGroups: List.generate(days, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: ys[i],
                        width: 6,
                        color: Colors.green,
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 40,
                      showTitles: true,
                      interval: interval,
                      getTitlesWidget: (v, meta) => Text(
                        useHours ? "${v.toInt()}h" : "${v.toInt()}m",
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        if (days > 25 && i % 3 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bigNumber(thisMonthSecs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  "${diffP >= 0 ? '+' : ''}${diffP.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 13,
                    color: diffP >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
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

// =========================================================
// Timeline Painter（中心 now ± 3hr）
// =========================================================
class _DayTimelinePainter extends CustomPainter {
  final List<Map<String, dynamic>> sessions;
  final int centerMinutes; // 0~1439

  _DayTimelinePainter({
    required this.sessions,
    required this.centerMinutes,
  });

  int _parseMinutes(String? hhmm) {
    if (hhmm == null) return 0;
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final h = size.height * 0.35;
    final top = (size.height - h) / 2;

    int startM = centerMinutes - 180;
    int endM = centerMinutes + 180;

    if (startM < 0) {
      endM -= startM;
      startM = 0;
    }
    if (endM > 1440) {
      final diff = endM - 1440;
      startM -= diff;
      endM = 1440;
      if (startM < 0) startM = 0;
    }

    final range = (endM - startM).toDouble();
    if (range <= 0) return;

    final fullRect = RRect.fromLTRBR(
      0, top, size.width, top + h,
      const Radius.circular(999),
    );
    canvas.drawRRect(fullRect, basePaint);

    for (final s in sessions) {
      final sm = _parseMinutes(s['start']);
      final em = _parseMinutes(s['end']);
      if (em <= sm) continue;

      final segStart = sm < startM ? startM : sm;
      final segEnd = em > endM ? endM : em;
      if (segEnd <= segStart) continue;

      final startRatio = (segStart - startM) / range;
      final endRatio = (segEnd - startM) / range;

      final left = size.width * startRatio;
      final right = size.width * endRatio;

      final segRect = RRect.fromLTRBR(
        left, top, right, top + h,
        const Radius.circular(999),
      );
      canvas.drawRRect(segRect, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DayTimelinePainter old) {
    return old.sessions != sessions || old.centerMinutes != centerMinutes;
  }
}
