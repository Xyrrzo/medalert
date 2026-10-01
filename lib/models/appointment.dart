class Appointment {
  final int id;
  final String patientName;
  final String type;
  final String date;
  final String time;
  final String status;
  final String? healthUnitName;
  final String? notes;

  Appointment({
    required this.id,
    required this.patientName,
    required this.type,
    required this.date,
    required this.time,
    required this.status,
    this.healthUnitName,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'],
        patientName: json['patient_name'] ?? '',
        type: json['appointment_type'],
        date: json['appointment_date'],
        time: json['appointment_time'],
        status: json['status'],
        healthUnitName: json['health_units']?['name'],
        notes: json['notes'],
      );
}