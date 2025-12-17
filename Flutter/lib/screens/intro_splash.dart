import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../login_page.dart';

class IntroSplash extends StatefulWidget {
  const IntroSplash({super.key});

  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _scaleLogo;
  late final Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeLogo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    );

    _scaleLogo = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeText = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      );
    });

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeLogo,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 🔹 Logo
              FadeTransition(
                opacity: _fadeLogo,
                child: ScaleTransition(
                  scale: _scaleLogo,
                  child: Image.asset(
                    'assets/splash/logo.png',
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 4), // 🔸 jarak lebih rapat ke teks

              // 🔹 Teks
              FadeTransition(
                opacity: _fadeText,
                child: Column(
                  children: const [
                    Text(
                      'I-TransEC',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hitung Emisimu, Selamatkan Bumi 🌍',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 🔹 Loading
              FadeTransition(
                opacity: _fadeText,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
