import 'package:cloud_firestore/cloud_firestore.dart';

class LabCase {
  final String id;
  final DateTime createdAt;
  final String employeeId;
  final String employeeName;
  final String caseName;
  final String unitType;
  final int unitsCount;
  final String doctorName;

  LabCase({
    required this.id,
    required this.createdAt,
    required this.employeeId,
    required this.employeeName,
    required this.caseName,
    required this.unitType,
    required this.unitsCount,
    required this.doctorName,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'createdAt': Timestamp.fromDate(createdAt),
      'employeeId': employeeId,
      'employeeName': employeeName,
      'caseName': caseName,
      'unitType': unitType,
      'unitsCount': unitsCount,
      'doctorName': doctorName,
    };
  }

  factory LabCase.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    DateTime parseCreatedAt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
      if (v is num) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(v.toInt());
        } catch (_) {}
      }
      // fallback: تاريخ قديم لتجنّب كسر الترتيب
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    int parseUnits(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return LabCase(
      id: doc.id,
      createdAt: parseCreatedAt(data['createdAt'] ?? data['Timestamp']),
      employeeId: (data['employeeId'] as String? ?? (data['Email'] as String? ?? data['email'] as String? ?? '')),
      employeeName: (data['employeeName'] as String? ?? data['EmployeeName'] as String? ?? ''),
      caseName: (data['caseName'] as String? ?? data['CaseName'] as String? ?? ''),
      unitType: (data['unitType'] as String? ?? data['UnitType'] as String? ?? ''),
      unitsCount: parseUnits(data['unitsCount'] ?? data['UnitsCount']),
      doctorName: (data['doctorName'] as String? ?? data['DoctorName'] as String? ?? ''),
    );
  }
}
