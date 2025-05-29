import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_button.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6F0), Color(0xFFFFE5B4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Welcome to Christ Chapel", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown[700])),
              SizedBox(height: 40),
              GradientButton(
                text: "Continue with Google",
                icon: Icons.login,
                onPressed: () => auth.signInWithGoogle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 