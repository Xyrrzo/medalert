import 'package:flutter/material.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_card.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final _controller = AnnouncementController();

  @override
  void initState() {
    super.initState();
    _controller.loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.error != null) {
          return Center(child: Text('Error: ${_controller.error}'));
        }
        return RefreshIndicator(
          onRefresh: _controller.loadAnnouncements,
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Health Advisories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_controller.announcements.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No advisories at the moment.')),
                )
              else
                ..._controller.announcements.map((a) => AnnouncementCard(announcement: a)),
            ],
          ),
        );
      },
    );
  }
}