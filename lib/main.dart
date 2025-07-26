import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/common/splash_screen.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Primary auth provider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          lazy: false, // Initialize immediately
        ),
        
        // Session provider that depends on auth
        ChangeNotifierProxyProvider<AuthProvider, SessionProvider>(
          create: (_) => SessionProvider(),
          update: (_, auth, session) {
            if (session == null) {
              session = SessionProvider();
            }
            session.update(auth);
            return session;
          },
        ),
        
        // Attendance provider that depends on auth
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, auth, attendance) {
            if (attendance == null) {
              attendance = AttendanceProvider();
            }
            attendance.update(auth);
            return attendance;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Attendance Scanner',
        theme: AppTheme.lightTheme,
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
