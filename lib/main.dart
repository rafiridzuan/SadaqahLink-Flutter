import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sadaqahlink/firebase_options.dart';
import 'package:sadaqahlink/screens/home_screen.dart';
import 'package:sadaqahlink/screens/login_screen.dart';
import 'package:sadaqahlink/services/auth_service.dart';
import 'package:sadaqahlink/services/notification_service.dart';
import 'package:sadaqahlink/providers/settings_provider.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sadaqahlink/services/connectivity_service.dart';

/// Background message handler - MUST be a top-level function
/// This handles notifications when app is in background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Data: ${message.data}');

  // Show local notification for data-only messages
  await NotificationService.showBackgroundNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configure foreground notification presentation (iOS)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle notification clicks when app is terminated
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      debugPrint('App opened from terminated state via notification');
      // Handle navigation based on message data
      // You can navigate to specific screen based on message.data
    }
  });

  // Handle notification clicks when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('App opened from background state via notification');
    // Handle navigation based on message data
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      NotificationService().showForegroundNotification(
        message.notification!.title ?? 'Notification',
        message.notification!.body ?? '',
      );
    }
  });

  // Check remember me preference
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? true;
  if (!rememberMe) {
    await FirebaseAuth.instance.signOut();
  }

  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Sadaqah Link',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A237E), // Deep Blue
                primary: const Color(0xFF1A237E),
                secondary: const Color(0xFF00BCD4), // Cyan Accent
                surface: Colors.white,
                background: const Color(0xFFF5F7FA), // Off-white
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF5F7FA),
              textTheme: GoogleFonts.poppinsTextTheme(),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A237E),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                surfaceTintColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1), // Indigo 500
                primary: const Color(0xFF6366F1),
                secondary: const Color(0xFF38BDF8), // Sky 400
                surface: const Color(0xFF1E293B), // Slate 800
                background: const Color(0xFF0F172A), // Slate 900
                onSurface: const Color(0xFFF1F5F9), // Slate 100
                onBackground: const Color(0xFFF8FAFC), // Slate 50
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
              textTheme:
                  GoogleFonts.poppinsTextTheme(
                    ThemeData.dark().textTheme,
                  ).apply(
                    bodyColor: const Color(0xFFF1F5F9), // Slate 100
                    displayColor: const Color(0xFFF8FAFC), // Slate 50
                  ),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1E293B), // Slate 800
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF334155), // Slate 700
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1), // Indigo 500
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo 500
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF1E293B), // Slate 800
                surfaceTintColor: const Color(0xFF1E293B),
              ),
              dialogBackgroundColor: const Color(0xFF1E293B), // Slate 800
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1E293B), // Slate 800
                selectedItemColor: Color(0xFF6366F1), // Indigo 500
                unselectedItemColor: Colors.grey,
              ),
            ),
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ms')],
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          // Initialize connectivity listener once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ConnectivityService().initialize(context);
          });

          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
