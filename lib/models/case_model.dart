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
    return LabCase(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      employeeId: data['employeeId'] as String,
      employeeName: data['employeeName'] as String,
      caseName: data['caseName'] as String,
      unitType: data['unitType'] as String,
      unitsCount: (data['unitsCount'] as num).toInt(),
      doctorName: data['doctorName'] as String,
    );
  }
}
