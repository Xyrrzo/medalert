import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});
  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _index = 0;
  final _appointmentSearch = TextEditingController();
  final _reportSearch = TextEditingController();
  String _appointmentFilter = 'all';
  String _reportFilter = 'open';
  Future<Map<String, int>> _overview =
      SupabaseService.instance.getStaffOverview();
  Future<List<Map<String, dynamic>>> _appointments =
      SupabaseService.instance.getAllAppointments();
  Future<List<Map<String, dynamic>>> _reports =
      SupabaseService.instance.getSymptomReports();
  Future<List<Map<String, dynamic>>> _announcements =
      SupabaseService.instance.getAnnouncements();
  void _refresh() => setState(() {
        _overview = SupabaseService.instance.getStaffOverview();
        _appointments = SupabaseService.instance.getAllAppointments();
        _reports = SupabaseService.instance.getSymptomReports();
        _announcements = SupabaseService.instance.getAnnouncements();
      });
  void _error(Object _) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('That action was denied or could not be completed.')));
  }

  @override
  void dispose() {
    _appointmentSearch.dispose();
    _reportSearch.dispose();
    super.dispose();
  }

  Future<void> _postAnnouncement() async {
    final title = TextEditingController(), body = TextEditingController();
    String category = AppConstants.announcementCategories.first;
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: const Text('Post advisory'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Title')),
                    TextField(
                        controller: body,
                        decoration: const InputDecoration(labelText: 'Message'),
                        maxLines: 3),
                    DropdownButtonFormField<String>(
                        initialValue: category,
                        items: AppConstants.announcementCategories
                            .map((v) =>
                                DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) =>
                            setDialog(() => category = v ?? category)),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Post'))
                  ],
                )));
    if (ok != true || title.text.trim().isEmpty || body.text.trim().isEmpty)
      return;
    try {
      await SupabaseService.instance.createAnnouncement(
          title: title.text.trim(), body: body.text.trim(), category: category);
      _refresh();
    } catch (e) {
      _error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Staff overview',
      'Appointments',
      'Symptom Reports',
      'Advisories'
    ];
    return Scaffold(
      appBar: GradientAppBar(title: 'MedAlert • ${titles[_index]}', actions: [
        IconButton(
            tooltip: 'Sign out',
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.white))
      ]),
      body: IndexedStack(index: _index, children: [
        _overviewPage(),
        _appointmentList(),
        _reportList(),
        _advisoryList()
      ]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
            NavigationDestination(
                icon: Icon(Icons.event), label: 'Appointments'),
            NavigationDestination(
                icon: Icon(Icons.health_and_safety), label: 'Reports'),
            NavigationDestination(
                icon: Icon(Icons.campaign), label: 'Advisories')
          ]),
    );
  }

  Widget _overviewPage() => FutureBuilder<Map<String, int>>(
      future: _overview,
      builder: (context, snap) {
        if (snap.hasError) return _failure(snap.error!);
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final counts = snap.data!;
        return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Today’s workload',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _summaryCard(
                  icon: Icons.event_note,
                  color: Colors.blue,
                  label: 'Pending appointments',
                  value: counts['pendingAppointments']!,
                  onTap: () => setState(() => _index = 1)),
              _summaryCard(
                  icon: Icons.today,
                  color: Colors.indigo,
                  label: 'Appointments today',
                  value: counts['appointmentsToday']!,
                  onTap: () => setState(() => _index = 1)),
              _summaryCard(
                  icon: Icons.event_available,
                  color: Colors.teal,
                  label: 'Confirmed appointments',
                  value: counts['confirmedAppointments']!,
                  onTap: () => setState(() => _index = 1)),
              _summaryCard(
                  icon: Icons.health_and_safety,
                  color: Colors.deepOrange,
                  label: 'Reports awaiting review',
                  value: counts['unhandledReports']!,
                  onTap: () => setState(() => _index = 2)),
              _summaryCard(
                  icon: Icons.priority_high,
                  color: Colors.red,
                  label: 'Critical reports',
                  value: counts['criticalReports']!,
                  onTap: () => setState(() => _index = 2)),
              _summaryCard(
                  icon: Icons.local_hospital,
                  color: Colors.green,
                  label: 'Open health units',
                  value: counts['openHealthUnits']!),
              _summaryCard(
                  icon: Icons.campaign_outlined,
                  color: Colors.purple,
                  label: 'Published advisories',
                  value: counts['announcements']!,
                  onTap: () => setState(() => _index = 3)),
              const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                      'Tap a card to open its queue. Pull down to refresh counts.')),
            ]));
      });

  Widget _summaryCard(
          {required IconData icon,
          required Color color,
          required String label,
          required int value,
          VoidCallback? onTap}) =>
      Card(
          child: ListTile(
              onTap: onTap,
              leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color)),
              title: Text(label),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right)
                ]
              ])));

  Widget _appointmentList() => FutureBuilder(
      future: _appointments,
      builder: (context, snap) {
        if (snap.hasError) return _failure(snap.error!);
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final query = _appointmentSearch.text.trim().toLowerCase();
        final rows = snap.data!.where((a) {
          final matchesStatus =
              _appointmentFilter == 'all' || a['status'] == _appointmentFilter;
          final haystack =
              '${a['patient_name'] ?? ''} ${a['appointment_type'] ?? ''} ${a['appointment_date'] ?? ''} ${a['health_units']?['name'] ?? ''}'
                  .toLowerCase();
          return matchesStatus && (query.isEmpty || haystack.contains(query));
        }).toList();
        return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              TextField(
                  controller: _appointmentSearch,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search patient, unit, type, or date',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final s in [
                      'all',
                      'pending',
                      'confirmed',
                      'completed',
                      'rejected'
                    ])
                      Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                              label: Text(s == 'all'
                                  ? 'All'
                                  : s[0].toUpperCase() + s.substring(1)),
                              selected: _appointmentFilter == s,
                              onSelected: (_) =>
                                  setState(() => _appointmentFilter = s)))
                  ])),
              if (rows.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                        child: Text('No appointments match this filter.'))),
              for (final a in rows)
                Card(
                    child: ListTile(
                        title: Text(
                            '${a['patient_name'] ?? 'Patient'} • ${a['appointment_type'] ?? ''}'),
                        subtitle: Text(
                            '${a['appointment_date'] ?? ''} ${a['appointment_time'] ?? ''} • ${a['status'] ?? ''}\n${a['health_units']?['name'] ?? ''}'),
                        isThreeLine: true,
                        trailing: a['status'] == 'pending'
                            ? PopupMenuButton<String>(
                                onSelected: (v) async {
                                  try {
                                    await SupabaseService.instance
                                        .updateAppointmentStatus(
                                            a['id'] as int, v);
                                    _refresh();
                                  } catch (e) {
                                    _error(e);
                                  }
                                },
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'confirmed',
                                          child: Text('Confirm')),
                                      PopupMenuItem(
                                          value: 'completed',
                                          child: Text('Complete')),
                                      PopupMenuItem(
                                          value: 'rejected',
                                          child: Text('Reject'))
                                    ])
                            : Chip(
                                label: Text(a['status']?.toString() ?? '')))),
            ]));
      });

  Widget _reportList() => FutureBuilder(
      future: _reports,
      builder: (context, snap) {
        if (snap.hasError) return _failure(snap.error!);
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final query = _reportSearch.text.trim().toLowerCase();
        final rows = snap.data!.where((r) {
          final handled = r['handled'] == true;
          final matchesStatus = _reportFilter == 'all' ||
              (_reportFilter == 'handled' ? handled : !handled);
          final haystack =
              '${r['severity'] ?? ''} ${r['symptoms'] ?? ''} ${r['notes'] ?? ''}'
                  .toLowerCase();
          return matchesStatus && (query.isEmpty || haystack.contains(query));
        }).toList();
        const order = {
          'critical': 0,
          'severe': 0,
          'high': 1,
          'moderate': 2,
          'mild': 3,
          'low': 3
        };
        rows.sort((a, b) {
          final bySeverity =
              (order[(a['severity'] as String?)?.toLowerCase()] ?? 4).compareTo(
                  order[(b['severity'] as String?)?.toLowerCase()] ?? 4);
          return bySeverity != 0
              ? bySeverity
              : (b['created_at'] ?? '')
                  .toString()
                  .compareTo((a['created_at'] ?? '').toString());
        });
        return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              TextField(
                controller: _reportSearch,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search symptoms or notes',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final f in ['open', 'handled', 'all'])
                  ChoiceChip(
                      label: Text(f == 'open'
                          ? 'Needs review'
                          : f[0].toUpperCase() + f.substring(1)),
                      selected: _reportFilter == f,
                      onSelected: (_) => setState(() => _reportFilter = f))
              ]),
              if (rows.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(28),
                    child:
                        Center(child: Text('No reports match this filter.'))),
              for (final r in rows)
                Card(
                    child: ListTile(
                        leading: Icon(
                            (r['severity']?.toString().toLowerCase() ==
                                        'severe' ||
                                    r['severity']?.toString().toLowerCase() ==
                                        'critical')
                                ? Icons.priority_high_rounded
                                : Icons.health_and_safety_outlined,
                            color: (r['severity']?.toString().toLowerCase() ==
                                        'severe' ||
                                    r['severity']?.toString().toLowerCase() ==
                                        'critical')
                                ? Colors.red
                                : Colors.orange),
                        title: Text('${r['severity'] ?? 'Unknown'} severity'),
                        subtitle:
                            Text('${r['symptoms'] ?? ''}\n${r['notes'] ?? ''}'),
                        isThreeLine: true,
                        trailing: Checkbox(
                            value: r['handled'] == true,
                            onChanged: (v) async {
                              try {
                                await SupabaseService.instance
                                    .markSymptomReportHandled(
                                        r['id'] as int, v ?? false);
                                _refresh();
                              } catch (e) {
                                _error(e);
                              }
                            }))),
            ]));
      });

  Widget _advisoryList() => FutureBuilder(
      future: _announcements,
      builder: (context, snap) {
        if (snap.hasError) return _failure(snap.error!);
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              FilledButton.icon(
                  onPressed: _postAnnouncement,
                  icon: const Icon(Icons.add),
                  label: const Text('Post advisory')),
              for (final a in snap.data!)
                Card(
                    child: ListTile(
                        title: Text(a['title']?.toString() ?? ''),
                        subtitle:
                            Text('${a['category'] ?? ''}\n${a['body'] ?? ''}'),
                        isThreeLine: true))
            ]));
      });

  Widget _failure(Object _) => const Center(
      child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Unable to load this section. Check your access or try again.')));
}
