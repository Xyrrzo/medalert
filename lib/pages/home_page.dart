import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_app_bar.dart';
import 'announcements_page.dart';
import 'directory_page.dart';
import 'emergency_page.dart';
import 'reminders_page.dart';
import 'schedule_page.dart';
import 'health_tools_page.dart';

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
    HealthToolsPage(showAppBar: false),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.event_note), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.sos), label: 'Emergency'),
    NavigationDestination(icon: Icon(Icons.medication), label: 'Meds'),
    NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Directory'),
    NavigationDestination(icon: Icon(Icons.campaign), label: 'Advisories'),
    NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), label: 'Tools'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'MedAlert', actions: [
        IconButton(tooltip: 'Health tools', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthToolsPage())), icon: const Icon(Icons.health_and_safety_outlined, color: Colors.white)),
        IconButton(tooltip: 'Sign out', onPressed: () => AuthService.instance.signOut(), icon: const Icon(Icons.logout, color: Colors.white)),
      ]),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }
}
