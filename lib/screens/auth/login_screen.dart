import 'package:cargo_flow/screens/auth/Splash_signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cargo_flow/services/auth_service.dart';
import 'package:cargo_flow/screens/customer/customer_home_screen.dart'
    as customer_screen;
import 'package:cargo_flow/screens/driver_home_screen.dart' as driver_screen;
import 'package:cargo_flow/screens/employee_dashboard_screen.dart'
    as employee_screen;
import 'package:cargo_flow/screens/admin_dashboard_screen.dart' as admin_screen;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoggedInUser();
  }

  Future<void> _checkLoggedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String role = "customer"; // default role
      try {
        role = await _authService.getUserRole(user.uid);
      } catch (_) {
        role = "customer";
      }
      _navigateToRoleScreen(role);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      User? user;

      // Special check for hardcoded admin
      if (email == "Ahmedadmin1@gmail.com" && password == "00000000A") {
        _navigateToRoleScreen("admin");
        return;
      }

      // Normal login via Firebase
      user = await _authService.loginWithEmail(email, password);

      if (user != null) {
        final role = await _authService.getUserRole(user.uid);
        _navigateToRoleScreen(role);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is invalid.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRoleScreen(String role) {
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
        homeScreen = const customer_screen.CustomerHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                  height: 300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login to continue",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your password' : null,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Login"),
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  RoleSelectionScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(Icons.g_mobiledata, Colors.red),
                    const SizedBox(width: 16),
                    _buildSocialIcon(Icons.facebook, Colors.blue),
                    const SizedBox(width: 16),
                    _buildSocialIcon(Icons.link, Colors.blueGrey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
