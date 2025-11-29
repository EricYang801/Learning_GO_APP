import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/announcement_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final annState = context.watch<AnnouncementState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        itemCount: annState.announcements.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final a = annState.announcements[i];
          return ListTile(
            title: Text(a.title),
            subtitle: Text(a.body),
            trailing: Text(
              a.at.toIso8601String().substring(0, 16).replaceFirst('T', ' '),
            ),
          );
        },
      ),
    );
  }
}
