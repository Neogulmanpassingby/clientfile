import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../main_app/Mainpage.dart'; // 추가: MainPage import
import 'package:go_router/go_router.dart';

class ClapAnimationPage extends StatelessWidget {
  final int mode; // 0 = Sign‑Up, 1 = Login
  final String nickname;

  const ClapAnimationPage({
    super.key,
    required this.mode,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSignUp = mode == 0;
    final String subtitle = isSignUp ? '회원가입 완료!' : '로그인 성공!';
    final String greet    = '$nickname님,\n환영해요!';

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // 탭하면 MainPage로 대체(Nav stack 리셋)
          context.go('/main');
        },
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRect(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: Transform.scale(
                        scale: 3.0,
                        child: Lottie.asset(
                          'assets/images/clap.json',
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                  const SizedBox(height: 16),
                  const Text(
                    '화면 어디든 탭하면 계속됩니다',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
