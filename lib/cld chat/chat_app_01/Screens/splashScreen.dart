import 'package:chat_app_cld/cld%20chat/chat_app_01/auth/authScreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../databaseServices/authDBService.dart';
import 'mainScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final hiveAuth = HiveAuthService();

    if (hiveAuth.isLoggedIn()) {
      // ✅ Navigate to main chat screen
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacementNamed(context, '/mainScreen');
      });
    } else {
      // ✅ Navigate to login
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacementNamed(context, '/loginScreen');
      });
    }


    // ✅ Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // ✅ Check user login on start
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // Dark theme

      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Replace with your app logo
              Image.asset(
                'assets/logo/splashlogo.png', // <-- Add your image in assets
                width: 120,
              ),
              SizedBox(height: 20),
              Text(
                "Chat App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
