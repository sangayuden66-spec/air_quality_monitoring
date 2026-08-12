import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/reports/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // TEMPORARY: replace with the real logged-in user once
  // Authentication is merged in. Randomized per launch so reports
  // submitted in earlier test sessions can still be voted on.
  final String _testUserId =
      'test-user-${DateTime.now().millisecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Monitoring',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: ReportsScreen(
        currentUserId: _testUserId,
        currentUserName: 'Nayan (Test)',
      ),
    );
  }
}