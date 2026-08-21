import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_options.dart';
import 'core/services/user_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/alerts/services/alert_service.dart';
import 'features/alerts/services/alert_preference_service.dart';
import 'features/alerts/screens/alert_settings_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'screens/user_dashboard.dart';
import 'screens/analytics_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/map_screen.dart';

// Global key for navigation without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();

    final fcmService = FcmService();
    await fcmService.init();

    // Handle taps on local notifications (foreground FCM)
    notificationService.onNotificationTap = (payload) {
      if (payload == 'aqi_dashboard' || payload == 'aqi_alert') {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const AlertsScreen()),
        );
      }
    };
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Air Quality Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  LatLng _selectedLocation = const LatLng(-35.2809, 149.1300);
  final AlertService _alertService = AlertService();
  final AlertPreferenceService _alertPreferenceService =
      AlertPreferenceService();

  @override
  void initState() {
    super.initState();
    UserService().ensureUserDocument();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateGlobalLocation(LatLng newLocation) {
    setState(() {
      _selectedLocation = newLocation;
      _selectedIndex = 0;
    });
    _syncAlertPreferenceLocation(newLocation);
  }

  Future<void> _syncAlertPreferenceLocation(LatLng location) async {
    try {
      await _alertPreferenceService.syncLocationWithSelection(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      debugPrint('Failed to auto-sync alert location: $e');
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'User Dashboard';
      case 1:
        return 'Analytics';
      case 2:
        return 'Location Map';
      case 3:
        return 'Community Reports';
      case 4:
        return 'Settings';
      default:
        return 'User Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      UserDashboard(
        location: _selectedLocation,
        onViewAllReports: () => _onItemTapped(3),
        onViewMap: () => _onItemTapped(2),
      ),
      AnalyticsScreen(
        location: _selectedLocation,
        onBackToHome: () => _onItemTapped(0),
      ),
      MapScreen(onLocationConfirmed: _updateGlobalLocation),
      const ReportsScreen(),
      const AlertSettingsScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 1
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                StreamBuilder<int>(
                  stream: _alertService.getUnreadCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AlertsScreen(),
                          ),
                        );
                      },
                      icon: Badge(
                        label: Text('$count'),
                        isLabelVisible: count > 0,
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
