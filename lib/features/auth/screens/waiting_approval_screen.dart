import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class WaitingApprovalScreen extends StatelessWidget {
  const WaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Menunggu Konfirmasi Admin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Akun Anda sudah terdaftar. Admin sedang memeriksa data Anda. Silakan hubungi Admin atau coba login kembali nanti.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const LoginScreen())
                    );
                  }
                },
                child: const Text('Kembali ke Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
