import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ClapAnimationPage
/// mode: 0 = 회원가입 완료, 1 = 로그인 성공
/// username: 표시할 사용자 이름 (선택)
class ClapAnimationPage extends StatelessWidget {
  final int mode; // 0 = Sign‑Up, 1 = Login
  final String username;

  const ClapAnimationPage({
    super.key,
    required this.mode,
    this.username = '사용자',
  });

  @override
  Widget build(BuildContext context) {
    final bool isSignUp = mode == 0;
    final String subtitle = isSignUp ? '회원가입 완료!' : '로그인 성공!';
    final String greet    = '$username님,\n환영해요!';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie 애니메이션 (3배 확대 후 ClipRect로 잘라냄)
                ClipRect(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Transform.scale(
                      scale: 3.0,
                      child: Lottie.asset(
                        'assets/images/clap.json', // pubspec.yaml 에 선언 필요
                        repeat: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  greet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}