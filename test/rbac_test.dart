import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medalert/models/app_role.dart';
import 'package:medalert/pages/role_home_router.dart';

void main() {
  test('role parsing maps unknown values to least-privilege patient', () {
    expect(AppRoleParsing.parse('ADMIN'), AppRole.admin);
    expect(AppRoleParsing.parse('MEDSTAFF'), AppRole.medstaff);
    expect(AppRoleParsing.parse('USER'), AppRole.patient);
    expect(AppRoleParsing.parse('unexpected'), AppRole.patient);
    expect(AppRoleParsing.parse(null), AppRole.patient);
  });

  test('role destinations are restricted by role', () {
    expect(destinationsForRole(AppRole.patient), [AppDestination.schedule, AppDestination.emergency, AppDestination.meds, AppDestination.directory, AppDestination.advisories]);
    expect(destinationsForRole(AppRole.medstaff), containsAll([AppDestination.appointments, AppDestination.symptomReports, AppDestination.advisories]));
    expect(destinationsForRole(AppRole.medstaff), isNot(contains(AppDestination.users)));
    expect(destinationsForRole(AppRole.admin), containsAll([AppDestination.users, AppDestination.healthUnits]));
  });

  testWidgets('patient router never builds staff or admin screens', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RoleHomeRouter(role: AppRole.patient, patient: const Text('patient home'), staff: const Text('staff screen'), admin: const Text('admin screen'))));
    expect(find.text('patient home'), findsOneWidget);
    expect(find.text('staff screen'), findsNothing);
    expect(find.text('admin screen'), findsNothing);
  });
}
