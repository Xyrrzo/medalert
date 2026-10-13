enum AppRole { admin, medstaff, patient }

extension AppRoleParsing on AppRole {
  String get databaseValue => switch (this) {
        AppRole.admin => 'ADMIN',
        AppRole.medstaff => 'MEDSTAFF',
        AppRole.patient => 'PATIENT',
      };

  static AppRole parse(Object? value) => switch (value?.toString().toUpperCase()) {
        'ADMIN' => AppRole.admin,
        'MEDSTAFF' => AppRole.medstaff,
        _ => AppRole.patient,
      };
}

enum AppDestination { schedule, emergency, meds, directory, advisories, overview, appointments, symptomReports, users, healthUnits }

List<AppDestination> destinationsForRole(AppRole role) => switch (role) {
      AppRole.patient => const [AppDestination.schedule, AppDestination.emergency, AppDestination.meds, AppDestination.directory, AppDestination.advisories],
      AppRole.medstaff => const [AppDestination.overview, AppDestination.appointments, AppDestination.symptomReports, AppDestination.advisories],
      AppRole.admin => const [AppDestination.overview, AppDestination.appointments, AppDestination.symptomReports, AppDestination.advisories, AppDestination.users, AppDestination.healthUnits],
    };
