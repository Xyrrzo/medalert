import 'package:flutter/widgets.dart';
import '../models/app_role.dart';
import 'admin_home_page.dart';
import 'home_page.dart';
import 'staff_home_page.dart';

class RoleHomeRouter extends StatelessWidget {
  const RoleHomeRouter({super.key, required this.role, this.patient, this.staff, this.admin});
  final AppRole role;
  final Widget? patient, staff, admin;

  @override
  Widget build(BuildContext context) => switch (role) {
        AppRole.patient => patient ?? const HomePage(),
        AppRole.medstaff => staff ?? const StaffHomePage(),
        AppRole.admin => admin ?? const AdminHomePage(),
      };
}
