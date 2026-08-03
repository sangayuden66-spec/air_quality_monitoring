import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/alerts/screens/notification_preferences_screen.dart';
// import 'features/alerts/services/alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Commenting out Firebase initialization for now so you can see the layout without Firebase setup.
  /*
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  */
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const MyHomePage(title: 'Air Quality Monitoring'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // final AlertService _alertService = AlertService();

  void _simulateHighAQI() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulation clicked (Firebase disabled)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Notification Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.air, size: 100, color: Colors.teal),
            const SizedBox(height: 24),
            Text(
              'Alerts and Notifications',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen()),
              ),
              icon: const Icon(Icons.notifications),
              label: const Text('View Alerts'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 50),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _simulateHighAQI,
              icon: const Icon(Icons.bolt),
              label: const Text('Simulate High AQI (155)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
