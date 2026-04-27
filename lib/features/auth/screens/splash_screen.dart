import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'waiting_approval_screen.dart';
import '../../admin/screens/admin_dashboard.dart';
import '../../user/screens/user_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRoute();
  }

  void _checkRoute() async {
    final authService = AuthService();
    
    try {
      final status = await authService.checkLoginStatus();
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (status != null) {
        final role = status['role'];
        final isApproved = status['isApproved'];

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else {
          if (isApproved) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
          }
        }
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      print("DEBUG ERROR: $e");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work, size: 80, color: Colors.indigo),
            SizedBox(height: 16),
            Text('SobatKost', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
