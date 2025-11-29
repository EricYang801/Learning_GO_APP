import 'package:intl/intl.dart';

final dateFmt = DateFormat('yyyy-MM-dd');
final timeFmt = DateFormat('HH:mm');
String humanDue(DateTime d) => DateFormat('EEE, MMM d').format(d);
String hhmm(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
