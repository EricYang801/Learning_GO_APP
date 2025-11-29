import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/timer_record.dart';
import '../../home/state/timer_state.dart';
import '../../home/widgets/section_card.dart';
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
  bool _showDistribution = true;

  @override
  Widget build(BuildContext context) {
    final timer = Provider.of<TimerState>(context);

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
        children: [
          if (_showToday) _buildTodayTimelineChart(timer),
          if (_showWeek) _buildWeekChart(timer),
          if (_showMonth) _buildMonthChart(timer),
          if (_showDistribution) _buildDistributionTable(timer),
        ],
      ),
    );
  }

  // 右側選單
  Widget _buildRightMenu(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    const blueThumb = Color(0xFF007AFF); // 藍色圓點
    final lightGrayTrack = Colors.grey.shade300; // OFF 狀態淺灰背景

    return Drawer(
      width: width * 0.6,
      backgroundColor: Colors.white,
      elevation: 16,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const Text(
              'Charts Menu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Today", style: TextStyle(fontSize: 16)),
              value: _showToday,
              activeTrackColor: blueThumb,
              inactiveTrackColor: lightGrayTrack,
              onChanged: (v) => setState(() => _showToday = v),
            ),
            SwitchListTile(
              title: const Text("This Week", style: TextStyle(fontSize: 16)),
              value: _showWeek,
              activeTrackColor: blueThumb,
              inactiveTrackColor: lightGrayTrack,
              onChanged: (v) => setState(() => _showWeek = v),
            ),
            SwitchListTile(
              title: const Text("This Month", style: TextStyle(fontSize: 16)),
              value: _showMonth,
              activeTrackColor: blueThumb,
              inactiveTrackColor: lightGrayTrack,
              onChanged: (v) => setState(() => _showMonth = v),
            ),
            SwitchListTile(
              title: const Text("Distribution", style: TextStyle(fontSize: 16)),
              value: _showDistribution,
              activeTrackColor: blueThumb,
              inactiveTrackColor: lightGrayTrack,
              onChanged: (v) => setState(() => _showDistribution = v),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Helpers
  // =========================================================

  double _calcDiffPercent(int current, int prev) {
    if (prev == 0) return current == 0 ? 0 : 100;
    return (current - prev) / prev * 100;
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
  // 格式化分鐘 => min/hr/day
  // =========================================================
  String _formatTime(int seconds, {bool big = false}) {
    final mins = seconds / 60.0;
    if (mins < 60) {
      return big
          ? "${mins.toStringAsFixed(0)} min"
          : "${mins.toStringAsFixed(0)}m";
    }
    final hrs = mins / 60.0;
    if (hrs < 24) {
      return big
          ? "${hrs.toStringAsFixed(1)} hr"
          : "${hrs.toStringAsFixed(1)}h";
    }
    final days = hrs / 24.0;
    return big
        ? "${days.toStringAsFixed(1)} day"
        : "${days.toStringAsFixed(1)}d";
  }

  // =========================================================
  // 今日 Timeline（中心現在時間 ± 3 小時）
  // =========================================================
  Widget _buildTodayTimelineChart(TimerState timer) {
    final now = DateTime.now();
    final sessions = timer.sessionsForDate(now);

    final nowMins = _nowMinutes();
    final todaySecs = timer.secondsForDate(now);
    final yesterdaySecs = timer.secondsForDate(
      now.subtract(const Duration(days: 1)),
    );
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
              // 大字時間
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _formatTime(todaySecs, big: true).split(' ')[0],
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                          " ${_formatTime(todaySecs, big: true).split(' ')[1]}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

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
    int clamp(int m) => m < 0 ? 0 : (m > 1439 ? 1439 : m);

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
        Text(
          fmt(center),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Text(fmt(rightMid), style: const TextStyle(fontSize: 11)),
        Text(fmt(rightMost), style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // =========================================================
  // 週 + 月 長條圖（不變）
  // =========================================================

  // =========================================================
  // Weekly Chart
  // =========================================================
  Widget _buildWeekChart(TimerState timer) {
    final now = DateTime.now();
    const weekdayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final rawMinutes = <double>[];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      rawMinutes.add(timer.secondsForDate(d) / 60.0);
      labels.add(weekdayLabel[d.weekday - 1]);
    }

    final thisWeekSecs = [
      for (int i = 0; i < 7; i++)
        timer.secondsForDate(now.subtract(Duration(days: i))),
    ].reduce((a, b) => a + b);

    final lastWeekSecs = [
      for (int i = 7; i < 14; i++)
        timer.secondsForDate(now.subtract(Duration(days: i))),
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
          SizedBox(height: 20),

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
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        int i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[i],
                          style: const TextStyle(fontSize: 11),
                        );
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
              _bigText(thisWeekSecs),
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

  Widget _bigText(int secs) {
    final formatted = _formatTime(secs, big: true).split(' ');
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: formatted[0],
            style: const TextStyle(
              fontSize: 32,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: " ${formatted[1]}",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 每月圖表
  // =========================================================
  Widget _buildMonthChart(TimerState timer) {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;
    final days = DateTime(y, m + 1, 0).day;

    final mins = <double>[];
    final labels = <String>[];

    for (int d = 1; d <= days; d++) {
      mins.add(timer.secondsForDate(DateTime(y, m, d)) / 60.0);
      labels.add(d.toString());
    }

    final thisMonthSecs = [
      for (int d = 1; d <= days; d++) timer.secondsForDate(DateTime(y, m, d)),
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
        timer.secondsForDate(DateTime(py, pm, d)),
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
          SizedBox(height: 20),

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
                        return Text(
                          labels[i],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
              _bigText(thisMonthSecs),
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
  // Study Time Distribution
  // =========================================================
  Widget _buildDistributionTable(TimerState timer) {
    final now = DateTime.now();

    // 今日所有時段
    final sessions = timer.sessionsForDate(now);

    // 四大時段秒數
    int morning = 0;
    int afternoon = 0;
    int evening = 0;
    int midnight = 0;

    for (final s in sessions) {
      final start = _parseMinutes(s.start);
      final end = _parseMinutes(s.end);
      if (end <= start) continue;

      for (int m = start; m < end; m++) {
        if (m >= 360 && m <= 779) {
          morning += 60;
        } else if (m >= 780 && m <= 1139) {
          afternoon += 60;
        } else if (m >= 1140 && m <= 1439) {
          evening += 60;
        } else {
          midnight += 60;
        }
      }
    }

    final total = morning + afternoon + evening + midnight;

    double pct(int v) {
      if (total == 0) return 0;
      return v * 100 / total;
    }

    // ⭐ 這裡加入「下方分隔線」
    Widget row(String label, int secs, {bool showDivider = true}) {
      final p = pct(secs);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                // 左欄：標題
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 中欄：時間
                Expanded(
                  child: Text(
                    _formatTime(secs, big: false),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),

                // 右欄：百分比
                SizedBox(
                  width: 70,
                  child: Text(
                    "${p.toStringAsFixed(1)}%",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: p >= 50 ? Colors.green : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ⭐ 分隔線（每列底部的淺灰色 line）
          if (showDivider)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 1,
              color: const Color.fromARGB(255, 211, 211, 211), // 淺灰色
            ),
        ],
      );
    }

    return SectionCard(
      title: "Study Time Distribution",
      tint: AppColors.softGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row("Morning", morning),
          row("Afternoon", afternoon),
          row("Evening", evening),
          row("Midnight", midnight, showDivider: false), // 最後一列不畫線
        ],
      ),
    );
  }
}

// =========================================================
// Timeline Painter（中心 now ± 3hr）
// =========================================================
class _DayTimelinePainter extends CustomPainter {
  final List<StudySession> sessions;
  final int centerMinutes; // 0~1439

  _DayTimelinePainter({required this.sessions, required this.centerMinutes});

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
      0,
      top,
      size.width,
      top + h,
      const Radius.circular(999),
    );
    canvas.drawRRect(fullRect, basePaint);

    for (final s in sessions) {
      final sm = _parseMinutes(s.start);
      final em = _parseMinutes(s.end);
      if (em <= sm) continue;

      final segStart = sm < startM ? startM : sm;
      final segEnd = em > endM ? endM : em;
      if (segEnd <= segStart) continue;

      final startRatio = (segStart - startM) / range;
      final endRatio = (segEnd - startM) / range;

      final left = size.width * startRatio;
      final right = size.width * endRatio;

      final segRect = RRect.fromLTRBR(
        left,
        top,
        right,
        top + h,
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
