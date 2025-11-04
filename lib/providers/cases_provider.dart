import 'dart:async';

import 'package:farah_new_lab/models/case_model.dart';
import 'package:farah_new_lab/services/case_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class CasesProvider extends ChangeNotifier {
  final CaseService _caseService;
  final String employeeId;

  CasesProvider({required CaseService caseService, required this.employeeId})
    : _caseService = caseService {
    _sub = _caseService
        .watchCasesForEmployee(employeeId)
        .listen((items) => _onCases(items));
  }

  List<LabCase> cases = <LabCase>[];
  bool loading = true;
  StreamSubscription<List<LabCase>>? _sub;
  DateTime? selectedMonth;

  void _onCases(List<LabCase> items) {
    cases = items;
    loading = false;
    notifyListeners();
  }

  // حساب بداية ونهاية الشهر (من 14 إلى 13)
  (DateTime start, DateTime end) _getMonthRange(DateTime month) {
    final start = DateTime(month.year, month.month, 14, 0, 0, 0);
    final end = DateTime(month.year, month.month + 1, 13, 23, 59, 59);
    return (start, end);
  }

  // الحالات المفلترة
  List<LabCase> get filteredCases {
    if (selectedMonth == null) {
      return cases;
    }
    
    final range = _getMonthRange(selectedMonth!);
    return cases.where((c) {
      return c.createdAt.isAfter(range.$1.subtract(const Duration(seconds: 1))) &&
             c.createdAt.isBefore(range.$2.add(const Duration(seconds: 1)));
    }).toList();
  }

  // إجمالي الوحدات للحالات المفلترة
  int get totalUnits => filteredCases.fold<int>(0, (sum, c) => sum + c.unitsCount);

  // تسمية الشهر المختار
  String get selectedMonthLabel {
    if (selectedMonth == null) {
      return 'جميع الشهور';
    }
    return DateFormat('MMMM yyyy', 'ar').format(selectedMonth!);
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth = month;
    notifyListeners();
  }

  void clearMonthFilter() {
    selectedMonth = null;
    notifyListeners();
  }

  Future<void> addCase(LabCase c) async {
    await _caseService.addCase(c);
  }

  Future<void> deleteCase(String caseId) async {
    await _caseService.deleteCase(employeeId, caseId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
