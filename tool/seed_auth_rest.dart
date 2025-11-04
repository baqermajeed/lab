import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class SeedUser {
  final String displayName;
  final String email;
  final String password;
  const SeedUser(this.displayName, this.email, this.password);
}

Future<void> main() async {
  // Read API key from android/app/google-services.json
  final gsPath = File('android/app/google-services.json');
  if (!await gsPath.exists()) {
    stderr.writeln('google-services.json not found at android/app');
    exit(1);
  }
  final jsonStr = await gsPath.readAsString();
  final data = json.decode(jsonStr) as Map<String, dynamic>;
  final apiKey =
      (data['client'] as List).first['api_key'][0]['current_key'] as String;

  final users = <SeedUser>[
    const SeedUser('المدير', 'manager@farahlab.com', 'Farah123!'),
    const SeedUser('موظف 1', 'employee1@farahlab.com', 'Farah123!'),
    const SeedUser('موظف 2', 'employee2@farahlab.com', 'Farah123!'),
    const SeedUser('موظف 3', 'employee3@farahlab.com', 'Farah123!'),
    const SeedUser('موظف 4', 'employee4@farahlab.com', 'Farah123!'),
    const SeedUser('موظف 5', 'employee5@farahlab.com', 'Farah123!'),
    const SeedUser('موظف 6', 'employee6@farahlab.com', 'Farah123!'),
  ];

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    final map = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(map['error'] ?? res.body);
    }
    return map;
  }

  for (final u in users) {
    try {
      // Create account
      final signUp = await _post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
        {'email': u.email, 'password': u.password, 'returnSecureToken': true},
      );
      final idToken = signUp['idToken'] as String;

      // Update display name
      await _post(
        'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey',
        {
          'idToken': idToken,
          'displayName': u.displayName,
          'returnSecureToken': false,
        },
      );

      stdout.writeln('Created: ${u.email}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('EMAIL_EXISTS')) {
        stdout.writeln('Exists: ${u.email}');
      } else {
        stderr.writeln('Error for ${u.email}: $e');
      }
    }
  }

  stdout.writeln(
    'Done. Note: user role docs will be created on first login by the app.',
  );
}
