import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farah_new_lab/models/case_model.dart';

class CaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cases(String employeeId) {
    return _db.collection('users').doc(employeeId).collection('cases');
  }

  Future<void> addCase(LabCase labCase) async {
    await _cases(labCase.employeeId).add(labCase.toMap());
  }

  Stream<List<LabCase>> watchCasesForEmployeeOrEmail(
    String employeeId,
    String employeeEmailLower,
    String employeeNameLower,
  ) {
    final trimmedEmployeeId = employeeId.trim();
    final emailLower = employeeEmailLower.trim();

    // Direct path: users/{uid}/cases – always safe and efficient
    final Stream<List<LabCase>> directPathStream = trimmedEmployeeId.isNotEmpty
        ? _cases(trimmedEmployeeId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snap) => snap.docs.map((d) => LabCase.fromDoc(d)).toList())
        : const Stream<List<LabCase>>.empty();

    // Global collectionGroup filter to include legacy Google Sheets imports (Email/employeeName fields)
    final Stream<List<LabCase>> collectionGroupStream =
        _db.collectionGroup('cases').snapshots().map((snap) {
      final results = <LabCase>[];
      for (final d in snap.docs) {
        final data = d.data();
        final empId = (data['employeeId'] as String?)?.toLowerCase() ?? '';
        final emailA = (data['Email'] as String?)?.toLowerCase() ?? '';
        final emailB = (data['email'] as String?)?.toLowerCase() ?? '';
      
        final nameA = (data['EmployeeName'] as String?)?.toLowerCase() ?? '';
        final nameB = (data['employeeName'] as String?)?.toLowerCase() ?? '';

        final matchById = trimmedEmployeeId.isNotEmpty && empId == trimmedEmployeeId.toLowerCase();
        final matchByEmail = emailLower.isNotEmpty && (emailA == emailLower || emailB == emailLower || empId == emailLower);
        final matchByName = employeeNameLower.isNotEmpty && (nameA == employeeNameLower || nameB == employeeNameLower);

        if (matchById || matchByEmail || matchByName) {
          results.add(LabCase.fromDoc(d));
        }
      }
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    });

    // Merge: prefer direct path docs but also include any legacy sheet imports matched by email/name
    final controller = StreamController<List<LabCase>>();
    List<LabCase> currentDirect = const [];
    List<LabCase> currentGroup = const [];

    void emitCombined() {
      final merged = <String, LabCase>{};
      for (final d in currentGroup) {
        merged[d.id] = d;
      }
      for (final d in currentDirect) {
        merged[d.id] = d; // override with direct path version
      }
      final out = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // ignore: discarded_futures
      controller.add(out);
    }

    final subA = directPathStream.listen((list) {
      currentDirect = list;
      emitCombined();
    });
    final subB = collectionGroupStream.listen((list) {
      currentGroup = list;
      emitCombined();
    });

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }
  
  List<LabCase> _mergeAndSortCases(List<LabCase> directCases, List<LabCase> groupCases) {
    // Merge and remove duplicates by document ID
    final Map<String, LabCase> merged = {};
    for (final case_ in directCases) {
      merged[case_.id] = case_;
    }
    for (final case_ in groupCases) {
      // Only add if not already in direct path (to avoid duplicates)
      if (!merged.containsKey(case_.id)) {
        merged[case_.id] = case_;
      }
    }
    
    final combined = merged.values.toList();
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  // Watch all cases across all employees (for admin searches)
  // Avoid requiring a Firestore index by sorting locally
  Stream<List<LabCase>> watchAllCases() {
    return _db
        .collectionGroup('cases')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => LabCase.fromDoc(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> deleteCase(String employeeId, String caseId) async {
    await _cases(employeeId).doc(caseId).delete();
  }
}
