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

  Stream<List<LabCase>> watchCasesForEmployeeOrEmail(String employeeId, String employeeEmailLower) {
    // نقرأ كل الحالات عبر collectionGroup ثم نفلتر محلياً إما بالـ uid أو بالإيميل (يدعم حقول مختلفة: employeeId أو Email/email)
    return _db
        .collectionGroup('cases')
        .snapshots()
        .map((snap) {
          final lowerUid = employeeId.toLowerCase();
          final list = snap.docs.where((d) {
            final data = d.data();
            final empId = (data['employeeId'] as String?)?.toLowerCase();
            final emailA = (data['Email'] as String?)?.toLowerCase();
            final emailB = (data['email'] as String?)?.toLowerCase();
            return empId == lowerUid || empId == employeeEmailLower ||
                   emailA == employeeEmailLower || emailB == employeeEmailLower;
          }).map((d) => LabCase.fromDoc(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
