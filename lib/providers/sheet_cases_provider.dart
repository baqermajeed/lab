import 'dart:async';
import 'dart:convert';

import 'package:farah_new_lab/models/case_model.dart';
import 'package:farah_new_lab/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class SheetCase {
  final DateTime createdAt;
  final String employeeId;
  final String employeeName;
  final String caseName;
  final String unitType;
  final int unitsCount;
  final String doctorName;

  SheetCase({
    required this.createdAt,
    required this.employeeId,
    required this.employeeName,
    required this.caseName,
    required this.unitType,
    required this.unitsCount,
    required this.doctorName,
  });

  factory SheetCase.fromSheet(
    Map<String, dynamic> m, {
    required String uid,
    required String displayName,
  }) {
    DateTime ts;
    final rawTs = m['Timestamp'];
    if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is DateTime) {
      ts = rawTs;
    } else {
      ts = DateTime.now();
    }
    return SheetCase(
      createdAt: ts,
      employeeId: uid,
      employeeName: displayName,
      caseName: '${m['Case Name'] ?? ''}',
      unitType: '${m['Unit Type'] ?? ''}',
      unitsCount: int.tryParse('${m['Units Count'] ?? 0}') ?? 0,
      doctorName: '${m['Doctor Name'] ?? ''}',
    );
  }

  // محول بسيط لعرضها مع واجهة LabCase الحالية
  LabCase toLabCaseLike() {
    return LabCase(
      id: 'sheet_${employeeId}_${createdAt.millisecondsSinceEpoch}',
      createdAt: createdAt,
      employeeId: employeeId,
      employeeName: employeeName,
      caseName: caseName,
      unitType: unitType,
      unitsCount: unitsCount,
      doctorName: doctorName,
    );
  }
}

class SheetCasesProvider extends ChangeNotifier with WidgetsBindingObserver {
  final String webAppUrl;
  final String secretKey;
  final String email;
  final String uid;
  final String displayName;

  bool loading = false;
  DateTime? selectedMonth;
  DateTime? _last; // آخر توقيت وصلنا له
  Timer? _timer;

  final List<SheetCase> _all = [];

  SheetCasesProvider({
    required this.webAppUrl,
    required this.secretKey,
    required this.email,
    required this.uid,
    required this.displayName,
  }) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      final since = _last?.toIso8601String() ?? '';
      final uri = Uri.parse('$webAppUrl?key=$secretKey&email=$email&since=$since');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final List items = (body['items'] as List?) ?? [];
        for (final e in items) {
          final m = Map<String, dynamic>.from(e as Map);
          _all.add(SheetCase.fromSheet(m, uid: uid, displayName: displayName));
        }
        final lastIso = body['last'] as String?;
        if (lastIso != null) _last = DateTime.tryParse(lastIso) ?? _last;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  (DateTime, DateTime) _range(DateTime m) => (
        DateTime(m.year, m.month, 14, 0, 0, 0),
        DateTime(m.year, m.month + 1, 13, 23, 59, 59),
      );

  List<SheetCase> get filteredCases {
    if (selectedMonth == null) return List.unmodifiable(_all);
    final (s, e) = _range(selectedMonth!);
    return _all
        .where((c) => c.createdAt.isAfter(s.subtract(const Duration(seconds: 1))) &&
            c.createdAt.isBefore(e.add(const Duration(seconds: 1))))
        .toList();
  }

  List<LabCase> get filteredAsLabCases =>
      filteredCases.map((e) => e.toLabCaseLike()).toList();

  int get totalUnits => filteredCases.fold(0, (a, c) => a + c.unitsCount);

  String get selectedMonthLabel =>
      selectedMonth == null ? 'جميع الشهور' :
      '${selectedMonth!.month}-${selectedMonth!.year}';

  void setSelectedMonth(DateTime m) {
    selectedMonth = m;
    notifyListeners();
  }

  void clearMonthFilter() {
    selectedMonth = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
