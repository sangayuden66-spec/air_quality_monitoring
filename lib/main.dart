import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'core/services/access_control_service.dart';
import 'core/services/user_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/alerts/services/alert_service.dart';
import 'features/alerts/services/alert_preference_service.dart';
import 'features/alerts/screens/alert_settings_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'screens/user_dashboard.dart';
import 'screens/analytics_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/map_screen.dart';
import 'features/it/screens/it_main_screen.dart';

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
      theme: AppTheme.lightTheme(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final UserService _userService = UserService();
  final AccessControlService _accessControlService = AccessControlService();
  String? _ensuredUid;
  String? _touchedUid;
  bool _isHandlingDisabledUser = false;

  void _ensureUserDoc(String uid) {
    if (_ensuredUid == uid) return;
    _ensuredUid = uid;
    _userService.ensureUserDocument();
  }

  void _touchActivity(String uid) {
    if (_touchedUid == uid) return;
    _touchedUid = uid;
    _userService.touchCurrentUserActivity();
  }

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
          final authUser = snapshot.data!;
          _ensureUserDoc(authUser.uid);

          return StreamBuilder<UserAccessState?>(
            stream: _accessControlService.watchUserAccessByUid(authUser.uid),
            builder: (context, accessSnapshot) {
              if (accessSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (accessSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to load account access state: ${accessSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              final access = accessSnapshot.data;
              if (access == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (access.isDisabled) {
                if (!_isHandlingDisabledUser) {
                  _isHandlingDisabledUser = true;
                  Future.microtask(() => FirebaseAuth.instance.signOut());
                }
                return const Scaffold(
                  body: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Your account has been disabled. Please contact an administrator.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              _isHandlingDisabledUser = false;
              _touchActivity(authUser.uid);

              if (access.canAccessAdminRoutes) {
                return const AdminMainScreen();
              }
              if (access.canAccessITRoutes) {
                return const ItMainScreen();
              }
              return const MainScreen();
            },
          );
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
  LatLng? _selectedLocation;
  bool _isResolvingLocation = true;
  String? _locationError;
  final AlertService _alertService = AlertService();
  final AlertPreferenceService _alertPreferenceService =
      AlertPreferenceService();

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await UserService().ensureUserDocument();
    await _resolveInitialLocation();
  }

  Future<void> _resolveInitialLocation() async {
    if (!mounted) return;
    setState(() {
      _isResolvingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _determineCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _selectedLocation = location;
        _isResolvingLocation = false;
      });

      try {
        await _alertPreferenceService.syncLocationWithSelection(
          latitude: location.latitude,
          longitude: location.longitude,
          locationName: 'Current Location',
          updateExisting: false,
        );
      } catch (e) {
        debugPrint(
          'Failed to initialize alert location from device location: $e',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _isResolvingLocation = false;
      });
    }
  }

  Future<Position> _determineCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable them and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it from system settings.',
      );
    }

    return Geolocator.getCurrentPosition();
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
    if (_isResolvingLocation) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_selectedLocation == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, color: Colors.red, size: 44),
                const SizedBox(height: 12),
                Text(
                  _locationError ?? 'Unable to determine current location.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _resolveInitialLocation,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selectedLocation = _selectedLocation!;
    final List<Widget> screens = [
      UserDashboard(
        location: selectedLocation,
        onViewAllReports: () => _onItemTapped(3),
        onViewMap: () => _onItemTapped(2),
      ),
      AnalyticsScreen(
        location: selectedLocation,
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
              backgroundColor: AppThemeColors.surface,
              elevation: 0,
              title: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  color: AppThemeColors.textPrimary,
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
                          color: AppThemeColors.textPrimary,
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
        selectedItemColor: AppThemeColors.primary,
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
