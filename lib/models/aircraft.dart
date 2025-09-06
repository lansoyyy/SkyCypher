import 'package:cloud_firestore/cloud_firestore.dart';

class Aircraft {
  final String id;
  String name;
  final String? rpNumber;
  final String status;
  final bool isAvailable;
  final String? note;
  final DateTime updatedAt;
  // New field to store multiple RP numbers with their statuses
  final List<RpEntry> rpEntries;

  Aircraft({
    required this.id,
    required this.name,
    this.rpNumber,
    required this.status,
    required this.isAvailable,
    this.note,
    required this.updatedAt,
    this.rpEntries = const [],
  });

  // Create an Aircraft from Firestore document
  factory Aircraft.fromDocument(Map<String, dynamic> data, String id) {
    List<RpEntry> rpEntries = [];
    if (data['rpEntries'] != null) {
      rpEntries = (data['rpEntries'] as List)
          .map((e) => RpEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return Aircraft(
      id: id,
      name: data['name'] ?? '',
      rpNumber: data['rpNumber'],
      status: data['status'] ?? 'Available',
      isAvailable: data['isAvailable'] ?? true,
      note: data['note'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      rpEntries: rpEntries,
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
      'rpEntries': rpEntries.map((e) => e.toMap()).toList(),
    };
  }
}

// New class to represent an RP entry with its status
class RpEntry {
  final String rpNumber;
  final String status;
  final DateTime addedAt;
  final String name;

  RpEntry(
      {required this.rpNumber,
      required this.status,
      required this.addedAt,
      required this.name});

  factory RpEntry.fromMap(Map<String, dynamic> data) {
    return RpEntry(
      name: data['name'] ?? '',
      rpNumber: data['rpNumber'] ?? '',
      status: data['status'] ?? 'Available',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rpNumber': rpNumber,
      'status': status,
      'addedAt': addedAt,
    };
  }
}
