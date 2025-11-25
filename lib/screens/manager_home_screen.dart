import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farah_new_lab/models/case_model.dart';
import 'package:farah_new_lab/providers/auth_provider.dart';
import 'package:farah_new_lab/services/case_service.dart';
import 'package:farah_new_lab/utils/constants.dart';
import 'package:farah_new_lab/widgets/app_shell.dart';
import 'package:farah_new_lab/screens/manager_user_cases_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _caseService = CaseService();
  // حالة البحث: نخزن البيانات محلياً لتجنب وميض التحميل مع كل حرف
  List<LabCase> _allCases = const <LabCase>[];
  bool _casesLoading = true;
  String? _casesError;
  StreamSubscription<List<LabCase>>? _casesSub;

  @override
  void initState() {
    super.initState();
    _casesSub = _caseService.watchAllCases().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _allCases = data;
          _casesLoading = false;
          _casesError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _casesLoading = false;
          _casesError = e.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _casesSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppShell(
        title: AppText.appTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // شريط البحث العام عن الحالات
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'ابحث عن حالة (الاسم/الطبيب/النوع)...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty)
              // عرض قائمة الموظفين كما كانت
              _EmployeesList()
            else
              // نتائج البحث عن الحالات عبر جميع الموظفين (من الحالة المخزّنة محلياً)
              Builder(builder: (context) {
                if (_casesLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (_casesError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('تعذر تحميل الحالات: $_casesError',
                          style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                    ),
                  );
                }
                final q = _searchQuery;
                final results = _allCases
                    .where((c) => c.caseName.toLowerCase().contains(q) ||
                        c.doctorName.toLowerCase().contains(q) ||
                        c.unitType.toLowerCase().contains(q))
                    .toList();
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.cardGradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('نتائج البحث: ${results.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...results.map((c) => _CaseResultTile(caseData: c)).toList(),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmployeesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.cardGradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.people_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الموظفين',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${docs.length} موظف',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...docs.map((doc) {
              final name = (doc.data()['displayName'] as String?) ?? 'بدون اسم';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManagerUserCasesScreen(
                            employeeId: doc.id,
                            employeeName: name,
                            employeeEmail: (doc.data()['email'] as String?)?.toLowerCase(),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: AppColors.cardGradient),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // إحصائيات الحالة والوحدات لكل موظف (تجلب من collectionGroup وتفلتر حسب uid أو email أو employeeName)
                                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collectionGroup('cases')
                                      .snapshots(),
                                  builder: (context, cs) {
                                    if (!cs.hasData) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          _StatChip(label: 'حالات', value: '0', color: AppColors.info),
                                          SizedBox(width: 8),
                                          _StatChip(label: 'وحدات', value: '0', color: AppColors.success),
                                        ],
                                      );
                                    }

                                    final uidLower = doc.id.toLowerCase();
                                    final emailLower = ((doc.data()['email'] as String?) ?? '').toLowerCase();
                                    final nameLower = name.toLowerCase();

                                    final docs = cs.data!.docs.where((d) {
                                      final data = d.data();
                                      final empId = (data['employeeId'] as String?)?.toLowerCase() ?? '';
                                      final emailA = (data['Email'] as String?)?.toLowerCase() ?? '';
                                      final emailB = (data['email'] as String?)?.toLowerCase() ?? '';
                                      
                                      final nameA = (data['EmployeeName'] as String?)?.toLowerCase() ?? '';
                                      final nameB = (data['employeeName'] as String?)?.toLowerCase() ?? '';

                                      // المطابقة على UID أو Email أو EmployeeName
                                      final matchesEmployee = 
                                          (uidLower.isNotEmpty && empId == uidLower) ||
                                          (emailLower.isNotEmpty && (emailA == emailLower || emailB == emailLower || empId == emailLower)) ||
                                          (nameLower.isNotEmpty && (nameA == nameLower || nameB == nameLower));

                                      return matchesEmployee;
                                    }).toList();

                                    final casesCount = docs.length;
                                    final unitsTotal = docs.fold<int>(0, (s, d) {
                                      final data = d.data();
                                      final v = data['unitsCount'] ?? data['UnitsCount'];
                                      if (v is num) return s + v.toInt();
                                      if (v is String) return s + (int.tryParse(v) ?? 0);
                                      return s;
                                    });

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StatChip(label: 'حالات', value: '$casesCount', color: AppColors.info),
                                        const SizedBox(width: 8),
                                        _StatChip(label: 'وحدات', value: '$unitsTotal', color: AppColors.success),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }
}

class _CaseResultTile extends StatelessWidget {
  final LabCase caseData;
  const _CaseResultTile({required this.caseData});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy', 'ar').format(caseData.createdAt);
    final time = DateFormat('hh:mm a', 'ar').format(caseData.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.cardGradient),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caseData.caseName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(time, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // التفاصيل
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow(Icons.person_rounded, 'الموظف', caseData.employeeName, AppColors.info),
                    const SizedBox(height: 12),
                    _detailRow(Icons.medical_information_rounded, 'نوع الوحدة', caseData.unitType, AppColors.secondary),
                    const SizedBox(height: 12),
                    _detailRow(Icons.local_hospital_rounded, 'الطبيب', caseData.doctorName, AppColors.primary),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${caseData.unitsCount}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
