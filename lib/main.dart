import 'package:farah_new_lab/providers/auth_provider.dart';
import 'package:farah_new_lab/screens/cases_screen.dart';
import 'package:farah_new_lab/screens/employee_home_screen.dart';
import 'package:farah_new_lab/screens/login_screen.dart';
import 'package:farah_new_lab/screens/manager_home_screen.dart';
import 'package:farah_new_lab/services/auth_service.dart';
import 'package:farah_new_lab/theme/app_theme.dart';
import 'package:farah_new_lab/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:farah_new_lab/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase will be configured after you share the Firebase options.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ],
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return MaterialApp(
              title: AppText.appTitle,
              theme: buildAppTheme(),
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('ar'), Locale('en')],
              locale: const Locale('ar'),
              routes: {
                '/login': (_) => const LoginScreen(),
                '/employee': (_) => const EmployeeHomeScreen(),
                '/cases': (_) => const CasesScreen(),
                '/manager': (_) => const ManagerHomeScreen(),
              },
              home: _buildHome(auth),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.currentUser == null) {
      return const LoginScreen();
    }
    if (auth.currentUser!.role == 'manager') {
      return const ManagerHomeScreen();
    }
    return const EmployeeHomeScreen();
  }
}
