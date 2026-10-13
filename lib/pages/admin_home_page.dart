import 'package:flutter/material.dart';
import '../models/app_role.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_app_bar.dart';
import 'staff_home_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _index = 0;
  Future<List<Map<String, dynamic>>> _users = SupabaseService.instance.getProfiles();
  Future<List<Map<String, dynamic>>> _units = SupabaseService.instance.getHealthUnits();
  void _refresh() => setState(() { _users = SupabaseService.instance.getProfiles(); _units = SupabaseService.instance.getHealthUnits(); });
  void _failure(Object _) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The change was denied or could not be completed.'))); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GradientAppBar(title: ['Clinical', 'Users', 'Health Units'][_index], actions: [IconButton(tooltip: 'Sign out', onPressed: () => AuthService.instance.signOut(), icon: const Icon(Icons.logout, color: Colors.white))]),
    body: IndexedStack(index: _index, children: [const StaffHomePage(), _usersPage(), _unitsPage()]),
    bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: (v) => setState(() => _index = v), destinations: const [NavigationDestination(icon: Icon(Icons.medical_services), label: 'Clinical'), NavigationDestination(icon: Icon(Icons.people), label: 'Users'), NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Units')]),
  );

  Widget _usersPage() => FutureBuilder(future: _users, builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Unable to load users.')); if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final rows = snap.data!;
    return RefreshIndicator(onRefresh: () async => _refresh(), child: ListView(children: [for (final user in rows) Builder(builder: (context) {
      final currentId = AuthService.instance.currentUser?.id;
      final role = AppRoleParsing.parse(user['role']);
      return ListTile(title: Text(user['full_name']?.toString().isNotEmpty == true ? user['full_name'].toString() : 'Unnamed user'), subtitle: Text('${user['id']} • ${role.databaseValue}'), trailing: DropdownButton<AppRole>(value: role, items: AppRole.values.map((v) => DropdownMenuItem(value: v, child: Text(v.databaseValue))).toList(), onChanged: role == AppRole.admin && user['id'] == currentId ? null : (next) async {
        if (next == null || next == role) return;
        if (user['id'] == currentId) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot change your own role.'))); return; }
        final admins = rows.where((e) => AppRoleParsing.parse(e['role']) == AppRole.admin).length;
        if (role == AppRole.admin && next != AppRole.admin && admins <= 1) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The last ADMIN cannot be demoted.'))); return; }
        final approved = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Change role?'), content: Text('Change this user from ${role.databaseValue} to ${next.databaseValue}?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm'))]));
        if (approved != true) return;
        try { await SupabaseService.instance.updateProfileRole(user['id'] as String, next.databaseValue); _refresh(); } catch(e) { _failure(e); }
      }));
    })]));
  });

  Future<void> _editUnit([Map<String, dynamic>? unit]) async {
    final name = TextEditingController(text: unit?['name']?.toString() ?? ''), address = TextEditingController(text: unit?['address']?.toString() ?? ''), phone = TextEditingController(text: unit?['phone']?.toString() ?? '');
    var open = unit?['is_open'] == true;
    final approved = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setDialog) => AlertDialog(title: Text(unit == null ? 'Add health unit' : 'Edit health unit'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')), TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')), SwitchListTile(value: open, onChanged: (v) => setDialog(() => open = v), title: const Text('Open'))])), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))])));
    if (approved != true || name.text.trim().isEmpty) return;
    try { await SupabaseService.instance.saveHealthUnit(id: unit?['id'] as int?, name: name.text.trim(), address: address.text.trim(), phone: phone.text.trim(), isOpen: open); _refresh(); } catch(e) { _failure(e); }
  }

  Widget _unitsPage() => FutureBuilder(future: _units, builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Unable to load health units.')); if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(onRefresh: () async => _refresh(), child: ListView(children: [Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(onPressed: () => _editUnit(), icon: const Icon(Icons.add), label: const Text('Add health unit'))), for (final unit in snap.data!) ListTile(title: Text(unit['name']?.toString() ?? ''), subtitle: Text('${unit['address'] ?? ''} • ${unit['phone'] ?? ''}'), leading: Icon(unit['is_open'] == true ? Icons.check_circle : Icons.cancel), onTap: () => _editUnit(unit), trailing: Switch(value: unit['is_open'] == true, onChanged: (v) async { try { await SupabaseService.instance.setHealthUnitOpen(unit['id'] as int, v); _refresh(); } catch(e) { _failure(e); } }))]));
  });
}
