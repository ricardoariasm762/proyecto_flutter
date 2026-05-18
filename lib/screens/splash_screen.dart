import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVisible = false;
  bool _hasNavigated = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Usamos el nombre exacto del archivo que subiste
    _controller =
        VideoPlayerController.asset('assets/videos/e_eb_c_a_f_f_b_mp_.mp4');

    try {
      await _controller.initialize().timeout(const Duration(seconds: 6));
      if (!mounted) return;
      setState(() {
        _isVisible = true;
      });
      await _controller.setLooping(false);
      _controller.play();

      // Escuchar cuando termine el video
      _controller.addListener(_handleVideoTick);
      _safetyTimer = Timer(const Duration(seconds: 10), () {
        _checkAuth();
      });
    } catch (e) {
      // Si el video local falla, intentar con uno de red o saltar al fallback
      _fallbackSequence();
    }
  }

  void _handleVideoTick() {
    if (_hasNavigated) return;
    final value = _controller.value;
    if (!value.isInitialized) return;

    final duration = value.duration;
    if (duration == Duration.zero) return;

    final isDone = value.isCompleted ||
        value.position >= duration - const Duration(milliseconds: 200);
    if (isDone) {
      _checkAuth();
    }
  }

  void _fallbackSequence() async {
    await Future.delayed(const Duration(seconds: 3));
    _checkAuth();
  }

  void _checkAuth() {
    if (!mounted) return;
    if (_hasNavigated) return;
    _hasNavigated = true;
    _safetyTimer?.cancel();
    _controller.removeListener(_handleVideoTick);

    final session = Supabase.instance.client.auth.currentSession;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            session != null ? const HomeScreen() : const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.removeListener(_handleVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'RIDEMATCH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          
          // Overlay para un fade out suave al final si es necesario
          AnimatedOpacity(
            opacity: _isVisible ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Container(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
