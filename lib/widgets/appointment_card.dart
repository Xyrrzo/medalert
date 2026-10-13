import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../utils/constants.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onCancel;

  const AppointmentCard({super.key, required this.appointment, this.onCancel});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppConstants.redPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status == 'cancelled';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _statusColor(appointment.status).withValues(alpha: 0.15),
          child: Icon(Icons.event, color: _statusColor(appointment.status)),
        ),
        title: Text(
          '${appointment.patientName} — ${appointment.type.toUpperCase()}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
            '${appointment.healthUnitName ?? ''}\n${appointment.date} at ${appointment.time} • ${appointment.status}'),
        isThreeLine: true,
        trailing: isCancelled
            ? null
            : TextButton(
                onPressed: onCancel,
                child: const Text('Cancel',
                    style: TextStyle(color: AppConstants.redPrimary)),
              ),
      ),
    );
  }
}
