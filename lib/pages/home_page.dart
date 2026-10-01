import 'package:flutter/material.dart';
import '../main.dart';
import 'announcements_page.dart';
import 'directory_page.dart';
import 'emergency_page.dart';
import 'reminders_page.dart';
import 'schedule_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _pages = [
    SchedulePage(),
    EmergencyPage(),
    RemindersPage(),
    DirectoryPage(),
    AnnouncementsPage(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.event_note), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.sos), label: 'Emergency'),
    NavigationDestination(icon: Icon(Icons.medication), label: 'Meds'),
    NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Directory'),
    NavigationDestination(icon: Icon(Icons.campaign), label: 'Advisories'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'MedAlert'),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }
}