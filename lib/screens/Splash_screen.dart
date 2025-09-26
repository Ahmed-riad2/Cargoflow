import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cargo_flow/services/auth_service.dart';
import 'package:cargo_flow/screens/customer/customer_home_screen.dart'
    as customer_screen;
import 'package:cargo_flow/screens/driver_home_screen.dart' as driver_screen;
import 'package:cargo_flow/screens/employee_dashboard_screen.dart'
    as employee_screen;
import 'package:cargo_flow/screens/admin_dashboard_screen.dart' as admin_screen;
import 'package:cargo_flow/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 5));

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String role = await _authService.getUserRole(user.uid);

      Widget homeScreen;
      switch (role) {
        case 'customer':
          homeScreen = const customer_screen.CustomerHomeScreen();
          break;
        case 'driver':
          homeScreen = const driver_screen.DriverHomeScreen();
          break;
        case 'employee':
          homeScreen = const employee_screen.EmployeeDashboardScreen();
          break;
        case 'admin':
          homeScreen = const admin_screen.AdminDashboardScreen();
          break;
        default:
          homeScreen = const LoginScreen();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => homeScreen),
        );
      }
    } else {
      // إذا لم يكن المستخدم مسجل الدخول
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: TextLiquidFill(
                text: 'Cargo Flow',
                waveColor: Colors.blueAccent,
                boxBackgroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 40,
                  fontFamily: 'ArchivoBlack', // استخدم خط Cargo Flow الجديد
                  fontWeight: FontWeight.bold,
                ),
                boxHeight: 200,
              ),
            ),
            const SizedBox(height: 30),

            /// اسم المطور
            SizedBox(
              width: 250.0,
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 24.0,
                  fontFamily: 'DancingScript', // استخدم خطك الخاص
                  color: Colors.black54,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [TyperAnimatedText('Eng. Ahmed Riad Ahmed')],
                  totalRepeatCount: 1,
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
