import 'package:chat_app_cld/cld%20chat/chat_app_01/AuthServices/authLocalService.dart';
import 'package:flutter/material.dart';
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

    final hiveAuth = AuthLocalService();

    // Optionally, add logging for clarity
    print('🛠 SplashScreen: isLoggedIn=${hiveAuth.isLoggedIn()}');
    print('🛠 SplashScreen: currentUser=${hiveAuth.getCurrentUser()}');

    Future.delayed(Duration(seconds: 2), () {
      if (hiveAuth.isLoggedIn()) {
        Navigator.pushReplacementNamed(context, '/mainScreen');
      } else {
        Navigator.pushReplacementNamed(context, '/loginScreen');
      }
    });

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo/splashlogo.png',
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
