import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../utils/constants.dart';

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback? onCall;

  const HospitalCard({super.key, required this.hospital, this.onCall});

  IconData get _icon {
    switch (hospital.type) {
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'clinic':
      case 'doctors':
        return Icons.medical_services;
      default:
        return Icons.local_hospital;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = hospital.phone != null && hospital.phone!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.redPrimary.withOpacity(0.12),
          child: Icon(_icon, color: AppConstants.redPrimary),
        ),
        title: Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${hospital.type.toUpperCase()} • ${hospital.address}'),
            if (hospital.hours != null) Text(hospital.hours!),
            
            if (hospital.distanceKm != null)
              Text(
                hospital.distanceLabel,
                style: TextStyle(
                  color: hospital.distanceKm! < 2 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        isThreeLine: hospital.hours != null || hospital.distanceKm != null,
        trailing: hasPhone
            ? Container(
                decoration: AppConstants.gradientBox(radius: 24),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: onCall,
                ),
              )
            : const Icon(Icons.phone_disabled, color: Colors.grey),
      ),
    );
  }
}