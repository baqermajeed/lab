import 'dart:async';

import 'package:farah_new_lab/models/case_model.dart';
import 'package:farah_new_lab/services/case_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class CasesProvider extends ChangeNotifier {
  final CaseService _caseService;
  final String employeeId;
  final String? employeeEmail;
  final String? employeeName;

  CasesProvider({
    required CaseService caseService,
    required this.employeeId,
    this.employeeEmail,
    this.employeeName,
  }) : _caseService = caseService {
    final emailLower = (employeeEmail ?? '').toLowerCase();
    final nameLower = (employeeName ?? '').toLowerCase();
    _sub = _caseService
        .watchCasesForEmployeeOrEmail(employeeId, emailLower, nameLower)
        .listen(
          (items) => _onCases(items),
          onError: (error) {
            debugPrint('Error loading cases: $error');
            // Don't clear existing cases on error, just stop loading
            // This prevents cases from disappearing when there's a temporary error
            if (loading) {
              loading = false;
              cases = [];
            }
            notifyListeners();
          },
        );
  }

  List<LabCase> cases = <LabCase>[];
  bool loading = true;
  StreamSubscription<List<LabCase>>? _sub;
  DateTime? selectedMonth;
  DateTime? startDate;
  DateTime? endDate;

  void _onCases(List<LabCase> items) {
    cases = items;
    loading = false;
    notifyListeners();
  }

  // حساب بداية ونهاية الشهر (من يوم 1 إلى نهاية الشهر)
  (DateTime start, DateTime end) _getMonthRange(DateTime month) {
    final start = DateTime(month.year, month.month, 1, 0, 0, 0);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return (start, end);
  }

  // الحالات المفلترة
  List<LabCase> get filteredCases {
    try {
      // إذا كان هناك فلترة حسب التاريخ (من - إلى)
      if (startDate != null && endDate != null) {
        try {
          final start = DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0);
          final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
          return cases.where((c) {
            try {
              return c.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                     c.createdAt.isBefore(end.add(const Duration(seconds: 1)));
            } catch (e) {
              debugPrint('Error filtering case by date: $e');
              return false;
            }
          }).toList();
        } catch (e) {
          debugPrint('Error in date range filter: $e');
          return cases;
        }
      }
      
      // إذا كان هناك فلترة حسب الشهر
      if (selectedMonth != null) {
        try {
          final range = _getMonthRange(selectedMonth!);
          return cases.where((c) {
            try {
              return c.createdAt.isAfter(range.$1.subtract(const Duration(seconds: 1))) &&
                     c.createdAt.isBefore(range.$2.add(const Duration(seconds: 1)));
            } catch (e) {
              debugPrint('Error filtering case by month: $e');
              return false;
            }
          }).toList();
        } catch (e) {
          debugPrint('Error in month filter: $e');
          return cases;
        }
      }
      
      return cases;
    } catch (e) {
      debugPrint('Error in filteredCases: $e');
      return cases;
    }
  }

  // إجمالي الوحدات للحالات المفلترة
  int get totalUnits {
    try {
      return filteredCases.fold<int>(0, (sum, c) {
        try {
          return sum + c.unitsCount;
        } catch (e) {
          debugPrint('Error calculating units: $e');
          return sum;
        }
      });
    } catch (e) {
      debugPrint('Error in totalUnits: $e');
      return 0;
    }
  }

  // تسمية الشهر المختار
  String get selectedMonthLabel {
    try {
      if (startDate != null && endDate != null) {
        return '${DateFormat('yyyy/MM/dd', 'ar').format(startDate!)} - ${DateFormat('yyyy/MM/dd', 'ar').format(endDate!)}';
      }
      if (selectedMonth == null) {
        return 'جميع الشهور';
      }
      return DateFormat('MMMM yyyy', 'ar').format(selectedMonth!);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      if (startDate != null && endDate != null) {
        return '${startDate!.year}/${startDate!.month}/${startDate!.day} - ${endDate!.year}/${endDate!.month}/${endDate!.day}';
      }
      if (selectedMonth != null) {
        return '${selectedMonth!.year}/${selectedMonth!.month}';
      }
      return 'جميع الشهور';
    }
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth = month;
    startDate = null;
    endDate = null;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate = start;
    endDate = end;
    selectedMonth = null;
    notifyListeners();
  }

  void clearMonthFilter() {
    selectedMonth = null;
    startDate = null;
    endDate = null;
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
