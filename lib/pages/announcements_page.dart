import 'package:flutter/material.dart';
import '../controllers/announcement_controller.dart';
import '../utils/constants.dart';
import '../widgets/announcement_card.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final _controller = AnnouncementController();
  String _query = '';
  String _category = 'all';

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
          return const Center(child: Text('Advisories could not be loaded. Check your connection and try again.'));
        }
        final query = _query.trim().toLowerCase();
        final filtered = _controller.announcements.where((a) =>
            (_category == 'all' || a.category == _category) &&
            (query.isEmpty || '${a.title} ${a.body} ${a.category}'.toLowerCase().contains(query))).toList();
        return RefreshIndicator(
          onRefresh: _controller.loadAnnouncements,
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Health Advisories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search advisories', border: OutlineInputBorder()))),
              const SizedBox(height: 8),
              SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [for (final c in ['all', ...AppConstants.announcementCategories]) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(c == 'all' ? 'All' : c.replaceAll('_', ' ')), selected: _category == c, onSelected: (_) => setState(() => _category = c)))])),
              if (_controller.announcements.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No advisories at the moment.')),
                )
              else if (filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No advisories match your search.')))
              else
                ...filtered.map((a) => AnnouncementCard(announcement: a)),
            ],
          ),
        );
      },
    );
  }
}
