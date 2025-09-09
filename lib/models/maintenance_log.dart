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

  // New fields for the requested details
  final String aircraftModel;
  final String aircraftRegNumber;
  final String aircraftParts;
  final String maintenanceTask;
  final String dateTimeStarted;
  final String dateTimeEnded;
  final String discrepancy;
  final String correctiveAction;
  final String componentRemarks;
  final String inspectedByFullName;

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
    // New fields
    required this.aircraftModel,
    required this.aircraftRegNumber,
    required this.aircraftParts,
    required this.maintenanceTask,
    required this.dateTimeStarted,
    required this.dateTimeEnded,
    required this.discrepancy,
    required this.correctiveAction,
    required this.componentRemarks,
    required this.inspectedByFullName,
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
      // New fields
      aircraftModel: data['aircraftModel'] ?? '',
      aircraftRegNumber: data['aircraftRegNumber'] ?? '',
      aircraftParts: data['aircraftParts'] ?? '',
      maintenanceTask: data['maintenanceTask'] ?? '',
      dateTimeStarted: data['dateTimeStarted'] ?? '',
      dateTimeEnded: data['dateTimeEnded'] ?? '',
      discrepancy: data['discrepancy'] ?? '',
      correctiveAction: data['correctiveAction'] ?? '',
      componentRemarks: data['componentRemarks'] ?? '',
      inspectedByFullName: data['inspectedByFullName'] ?? '',
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
      // New fields
      'aircraftModel': aircraftModel,
      'aircraftRegNumber': aircraftRegNumber,
      'aircraftParts': aircraftParts,
      'maintenanceTask': maintenanceTask,
      'dateTimeStarted': dateTimeStarted,
      'dateTimeEnded': dateTimeEnded,
      'discrepancy': discrepancy,
      'correctiveAction': correctiveAction,
      'componentRemarks': componentRemarks,
      'inspectedByFullName': inspectedByFullName,
    };
  }
}
