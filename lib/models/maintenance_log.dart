import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceLog {
  final String id;
  final String component;
  final String date;
  final String location;
  final String inspectedBy;
  final String aircraft;
  final String detailedInspection;
  final String reportedIssue;
  final String actionTaken;
  final String? imageUrl;
  final DateTime timestamp;

  MaintenanceLog({
    required this.id,
    required this.component,
    required this.date,
    required this.location,
    required this.inspectedBy,
    required this.aircraft,
    required this.detailedInspection,
    required this.reportedIssue,
    required this.actionTaken,
    this.imageUrl,
    required this.timestamp,
  });

  // Create a MaintenanceLog from Firestore document
  factory MaintenanceLog.fromDocument(Map<String, dynamic> data, String id) {
    return MaintenanceLog(
      id: id,
      component: data['component'] ?? '',
      date: data['date'] ?? '',
      location: data['location'] ?? '',
      inspectedBy: data['inspectedBy'] ?? '',
      aircraft: data['aircraft'] ?? '',
      detailedInspection: data['detailedInspection'] ?? '',
      reportedIssue: data['reportedIssue'] ?? '',
      actionTaken: data['actionTaken'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convert MaintenanceLog to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'component': component,
      'date': date,
      'location': location,
      'inspectedBy': inspectedBy,
      'aircraft': aircraft,
      'detailedInspection': detailedInspection,
      'reportedIssue': reportedIssue,
      'actionTaken': actionTaken,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }
}
