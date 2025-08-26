import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:skycypher/models/maintenance_log.dart';

class MaintenanceLogService {
  static final CollectionReference _maintenanceLogsCollection =
      FirebaseFirestore.instance.collection('maintenance_logs');

  // Get all maintenance logs stream
  static Stream<QuerySnapshot> getMaintenanceLogsStream() {
    return _maintenanceLogsCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add a new maintenance log
  static Future<void> addMaintenanceLog({
    required String component,
    required String date,
    required String location,
    required String inspectedBy,
    required String aircraft,
    required String detailedInspection,
    required String reportedIssue,
    required String actionTaken,
    File? image,
  }) async {
    String? imageUrl;

    // Upload image if provided
    if (image != null) {
      try {
        String fileName =
            'maintenance_logs/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageReference =
            FirebaseStorage.instance.ref().child(fileName);

        await storageReference.putFile(image);
        imageUrl = await storageReference.getDownloadURL();
      } catch (e) {
        // Handle image upload error
        throw Exception('Failed to upload image: $e');
      }
    }

    // Add log to Firestore
    await _maintenanceLogsCollection.add({
      'component': component,
      'date': date,
      'location': location,
      'inspectedBy': inspectedBy,
      'aircraft': aircraft,
      'detailedInspection': detailedInspection,
      'reportedIssue': reportedIssue,
      'actionTaken': actionTaken,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get a maintenance log by ID
  static Future<MaintenanceLog?> getMaintenanceLog(String id) async {
    try {
      DocumentSnapshot doc = await _maintenanceLogsCollection.doc(id).get();
      if (doc.exists) {
        return MaintenanceLog.fromDocument(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get maintenance log: $e');
    }
  }

  // Update a maintenance log
  static Future<void> updateMaintenanceLog(
      String id, MaintenanceLog maintenanceLog) async {
    try {
      await _maintenanceLogsCollection.doc(id).update(maintenanceLog.toMap());
    } catch (e) {
      throw Exception('Failed to update maintenance log: $e');
    }
  }

  // Delete a maintenance log
  static Future<void> deleteMaintenanceLog(String id) async {
    try {
      await _maintenanceLogsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete maintenance log: $e');
    }
  }
}
