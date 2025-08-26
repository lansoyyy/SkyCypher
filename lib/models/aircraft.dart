import 'package:cloud_firestore/cloud_firestore.dart';

class Aircraft {
  final String id;
  final String name;
  final String? rpNumber;
  final String status;
  final bool isAvailable;
  final String? note;
  final DateTime updatedAt;

  Aircraft({
    required this.id,
    required this.name,
    this.rpNumber,
    required this.status,
    required this.isAvailable,
    this.note,
    required this.updatedAt,
  });

  // Create an Aircraft from Firestore document
  factory Aircraft.fromDocument(Map<String, dynamic> data, String id) {
    return Aircraft(
      id: id,
      name: data['name'] ?? '',
      rpNumber: data['rpNumber'],
      status: data['status'] ?? 'Available',
      isAvailable: data['isAvailable'] ?? true,
      note: data['note'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Aircraft to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rpNumber': rpNumber,
      'status': status,
      'isAvailable': isAvailable,
      'note': note,
      'updatedAt': updatedAt,
    };
  }
}
