import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement.dart';
import '../utils/constants.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  Color _categoryColor(String category) {
    switch (category) {
      case 'outbreak':
        return AppConstants.redDark;
      case 'vaccination_drive':
        return Colors.green;
      case 'schedule_change':
        return Colors.orange;
      default:
        return AppConstants.redPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _categoryColor(announcement.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    announcement.category.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(announcement.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(announcement.body),
          ],
        ),
      ),
    );
  }
}