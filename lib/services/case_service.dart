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

  Stream<List<LabCase>> watchCasesForEmployee(String employeeId) {
    return _cases(employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LabCase.fromDoc(d)).toList());
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
