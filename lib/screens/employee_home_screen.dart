import 'package:farah_new_lab/models/case_model.dart';
import 'package:farah_new_lab/providers/auth_provider.dart';
import 'package:farah_new_lab/providers/cases_provider.dart';
import 'package:farah_new_lab/services/case_service.dart';
import 'package:farah_new_lab/utils/constants.dart';
import 'package:farah_new_lab/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseName = TextEditingController();
  final _unitsCount = TextEditingController();
  final _doctorName = TextEditingController();
  String _unitType = UnitTypes.all.first;
  late final String _today;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy/MM/dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _caseName.dispose();
    _unitsCount.dispose();
    _doctorName.dispose();
    super.dispose();
  }

  Future<void> _addCase(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;
    final labCase = LabCase(
      id: '',
      createdAt: DateTime.now(),
      employeeId: user.uid,
      employeeName: user.displayName,
      caseName: _caseName.text.trim(),
      unitType: _unitType,
      unitsCount: int.parse(_unitsCount.text.trim()),
      doctorName: _doctorName.text.trim(),
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await context.read<CasesProvider>().addCase(labCase);
    _caseName.clear();
    _unitsCount.clear();
    _doctorName.clear();
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('success')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    return ChangeNotifierProvider(
      create: (_) =>
          CasesProvider(caseService: CaseService(), employeeId: user.uid, employeeEmail: user.email),
      child: Builder(
        builder: (context) {
          final casesProv = context.watch<CasesProvider>();
          return Scaffold(
            appBar: AppShell(
              title: AppText.appTitle,
              actions: [
                IconButton(
                  icon: const Icon(Icons.table_view_outlined),
                  tooltip: 'عرض الحالات',
                  onPressed: () => Navigator.pushNamed(context, '/cases'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'تسجيل الخروج',
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
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: AppColors.cardGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'add new case',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                enabled: false,
                                initialValue: _today,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  labelText: ' Date ',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _caseName,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  labelText: 'case name',
                                  prefixIcon: Icon(
                                    Icons.medical_services_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'insert case name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _unitType,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                                items: UnitTypes.all
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => _unitType = v ?? UnitTypes.all.first,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'unit type',
                                  prefixIcon: Icon(
                                    Icons.category_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _unitsCount,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  labelText: 'unit number',
                                  prefixIcon: Icon(
                                    Icons.inventory_2_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'insert number';
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0) return 'ivalid number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _doctorName,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  labelText: 'doctor name',
                                  prefixIcon: Icon(
                                    Icons.local_hospital_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'insert doctor name' : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () => _addCase(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_circle_outline, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'add case',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.info.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.medical_information_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'cases number',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${casesProv.cases.length}',
                                      style: const TextStyle(
                                        color: AppColors.info,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'units number',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${casesProv.totalUnits}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
