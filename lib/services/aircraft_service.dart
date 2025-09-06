import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skycypher/models/aircraft.dart';

class AircraftService {
  static final CollectionReference _aircraftCollection =
      FirebaseFirestore.instance.collection('aircraft');

  // Get all aircraft stream
  static Stream<QuerySnapshot> getAircraftStream() {
    return _aircraftCollection.snapshots();
  }

  // Get aircraft by ID
  static Future<Aircraft?> getAircraft(String id) async {
    try {
      DocumentSnapshot doc = await _aircraftCollection.doc(id).get();
      if (doc.exists) {
        return Aircraft.fromDocument(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get aircraft: $e');
    }
  }

  // Add a new aircraft
  static Future<void> addAircraft(Aircraft aircraft) async {
    try {
      await _aircraftCollection.doc(aircraft.id).set(aircraft.toMap());
    } catch (e) {
      throw Exception('Failed to add aircraft: $e');
    }
  }

  // Update aircraft
  static Future<void> updateAircraft(Aircraft aircraft) async {
    try {
      await _aircraftCollection.doc(aircraft.id).update(aircraft.toMap());
    } catch (e) {
      throw Exception('Failed to update aircraft: $e');
    }
  }

  // Add a new RP entry to an aircraft
  static Future<void> addRpEntry(String aircraftId, RpEntry rpEntry) async {
    try {
      DocumentReference docRef = _aircraftCollection.doc(aircraftId);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Aircraft aircraft = Aircraft.fromDocument(
            docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);

        // Add the new RP entry to the list
        List<RpEntry> updatedRpEntries = List<RpEntry>.from(aircraft.rpEntries);
        updatedRpEntries.add(rpEntry);

        // Update the aircraft with the new RP entries
        Aircraft updatedAircraft = Aircraft(
          id: aircraft.id,
          name: aircraft.name,
          rpNumber: aircraft.rpNumber,
          status: aircraft.status,
          isAvailable: aircraft.isAvailable,
          note: aircraft.note,
          updatedAt: DateTime.now(),
          rpEntries: updatedRpEntries,
        );

        await updateAircraft(updatedAircraft);
      }
    } catch (e) {
      throw Exception('Failed to add RP entry: $e');
    }
  }

  // Update an existing RP entry
  static Future<void> updateRpEntry(String aircraftId, RpEntry rpEntry) async {
    try {
      DocumentReference docRef = _aircraftCollection.doc(aircraftId);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Aircraft aircraft = Aircraft.fromDocument(
            docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);

        // Find and update the RP entry
        List<RpEntry> updatedRpEntries = List<RpEntry>.from(aircraft.rpEntries);
        int index = updatedRpEntries
            .indexWhere((entry) => entry.rpNumber == rpEntry.rpNumber);

        if (index != -1) {
          updatedRpEntries[index] = rpEntry;
        } else {
          updatedRpEntries.add(rpEntry);
        }

        // Update the aircraft with the updated RP entries
        Aircraft updatedAircraft = Aircraft(
          id: aircraft.id,
          name: aircraft.name,
          rpNumber: aircraft.rpNumber,
          status: aircraft.status,
          isAvailable: aircraft.isAvailable,
          note: aircraft.note,
          updatedAt: DateTime.now(),
          rpEntries: updatedRpEntries,
        );

        await updateAircraft(updatedAircraft);
      }
    } catch (e) {
      throw Exception('Failed to update RP entry: $e');
    }
  }

  // Delete an RP entry
  static Future<void> deleteRpEntry(String aircraftId, String rpNumber) async {
    try {
      DocumentReference docRef = _aircraftCollection.doc(aircraftId);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Aircraft aircraft = Aircraft.fromDocument(
            docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);

        // Remove the RP entry from the list
        List<RpEntry> updatedRpEntries = List<RpEntry>.from(aircraft.rpEntries);
        updatedRpEntries.removeWhere((entry) => entry.rpNumber == rpNumber);

        // Update the aircraft with the updated RP entries
        Aircraft updatedAircraft = Aircraft(
          id: aircraft.id,
          name: aircraft.name,
          rpNumber: aircraft.rpNumber,
          status: aircraft.status,
          isAvailable: aircraft.isAvailable,
          note: aircraft.note,
          updatedAt: DateTime.now(),
          rpEntries: updatedRpEntries,
        );

        await updateAircraft(updatedAircraft);
      }
    } catch (e) {
      throw Exception('Failed to delete RP entry: $e');
    }
  }

  // Delete aircraft
  static Future<void> deleteAircraft(String id) async {
    try {
      await _aircraftCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete aircraft: $e');
    }
  }

  // Initialize default aircraft if they don't exist
  static Future<void> initializeDefaultAircraft() async {
    try {
      QuerySnapshot snapshot = await _aircraftCollection.get();

      // Check if we have the required aircraft
      bool hasCessna152 = false;
      bool hasCessna150 = false;

      for (var doc in snapshot.docs) {
        if (doc.id == 'cessna_152') hasCessna152 = true;
        if (doc.id == 'cessna_150') hasCessna150 = true;
      }

      final DateTime now = DateTime.now();

      // Add Cessna 152 if it doesn't exist
      if (!hasCessna152) {
        final Aircraft cessna152 = Aircraft(
          id: 'cessna_152',
          name: 'Cessna 152',
          rpNumber: '',
          status: 'Available',
          isAvailable: true,
          note: null,
          updatedAt: now,
          rpEntries: [
            RpEntry(
              rpNumber: 'RP-152-001',
              status: 'Available',
              addedAt: now,
              name: 'Cessna 152 RP 1',
            ),
            RpEntry(
              rpNumber: 'RP-152-002',
              status: 'Available',
              addedAt: now,
              name: 'Cessna 152 RP 2',
            ),
          ],
        );
        await addAircraft(cessna152);
      }

      // Add Cessna 150 if it doesn't exist
      if (!hasCessna150) {
        final Aircraft cessna150 = Aircraft(
          id: 'cessna_150',
          name: 'Cessna 150',
          rpNumber: '',
          status: 'Available',
          isAvailable: false,
          note: 'Currently not available',
          updatedAt: now,
          rpEntries: [
            RpEntry(
              rpNumber: 'RP-150-001',
              status: 'Under Maintenance',
              addedAt: now,
              name: 'Cessna 150 RP 1',
            ),
          ],
        );
        await addAircraft(cessna150);
      }
    } catch (e) {
      throw Exception('Failed to initialize default aircraft: $e');
    }
  }

  // Force reinitialize default aircraft (for testing purposes)
  static Future<void> forceReinitializeDefaultAircraft() async {
    try {
      final DateTime now = DateTime.now();

      // Create Cessna 152
      final Aircraft cessna152 = Aircraft(
        id: 'cessna_152',
        name: 'Cessna 152',
        rpNumber: '',
        status: 'Available',
        isAvailable: true,
        note: null,
        updatedAt: now,
        rpEntries: [
          RpEntry(
            rpNumber: 'RP-152-001',
            status: 'Available',
            addedAt: now,
            name: 'Cessna 152 RP 1',
          ),
          RpEntry(
            rpNumber: 'RP-152-002',
            status: 'Available',
            addedAt: now,
            name: 'Cessna 152 RP 2',
          ),
        ],
      );
      await updateAircraft(cessna152);

      // Create Cessna 150
      final Aircraft cessna150 = Aircraft(
        id: 'cessna_150',
        name: 'Cessna 150',
        rpNumber: '',
        status: 'Available',
        isAvailable: false,
        note: 'Currently not available',
        updatedAt: now,
        rpEntries: [
          RpEntry(
            rpNumber: 'RP-150-001',
            status: 'Under Maintenance',
            addedAt: now,
            name: 'Cessna 150 RP 1',
          ),
        ],
      );
      await updateAircraft(cessna150);
    } catch (e) {
      throw Exception('Failed to force reinitialize default aircraft: $e');
    }
  }
}
