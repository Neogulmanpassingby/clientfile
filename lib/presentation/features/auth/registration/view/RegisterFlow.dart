// lib/presentation/features/registration/view/register_flow.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:animations/animations.dart';
import 'package:cleanarea/core/config.dart';

import '../state/registration_provider.dart';
import '../widgets/step1_email.dart';
import '../widgets/step2_nickname.dart';
import '../widgets/step3_password.dart';
import '../widgets/step4_birthdate.dart';
import '../widgets/step5_income.dart';
import '../widgets/step6_address.dart';
import '../widgets/step7_survey.dart';

import 'package:go_router/go_router.dart';
import 'package:cleanarea/core/routes/app_router.dart' show ClapArgs;

class RegisterFlow extends StatefulWidget {
  const RegisterFlow({super.key});
  @override
  State<RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<RegisterFlow> {
  int _step = 0;
  bool _reverse = false;
  bool _loading = false;

  Future<void> _submit(RegistrationProvider p) async {
    setState(() => _loading = true);
    try {
      final body = p.toSignupJson();

      final resp = await http
          .post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('>>> REQUEST: ${jsonEncode(body)}');
      debugPrint('<<< RESPONSE: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 201) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final nickname = (json['nickname'] ?? p.nickname ?? '') as String;
        final token = json['token'] as String?;

        if (token != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'access_token', value: token);
          debugPrint('✅ 토큰 저장 완료');
        }

        if (!mounted) return;
        context.go(
          '/celebrate',
          extra: ClapArgs(mode: 1, nickname: nickname), // ← 위에서 정의한 타입
        );
        return;
      }

      _showSnack('회원가입 실패 (${resp.statusCode}) - ${resp.body}');
    } catch (e) {
      _showSnack('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _next()  => setState(() { _reverse = false; _step++; });
  void _prev()  { if (_step==0) return; setState(() { _reverse = true; _step--; }); }

  Widget _buildStep(int step, RegistrationProvider p) {
    switch (step) {
      case 0:
        return RegisterPage1(onNext: (v) { p.updateEmail(v); _next(); });
      case 1:
        return RegisterPage2(onNext: (v) { p.updateNickname(v); _next(); });
      case 2:
        return RegisterPage3(onNext: (v) { p.updatePassword(v); _next(); });
      case 3:
        return RegisterPage4(onNext: (v) { p.updateBirthDate(v); _next(); });
      case 4:
        return RegisterPage5(onNext: (v) { p.updateIncome(v); _next(); });
      case 5:
        return RegisterPage6(onComplete: (v) { p.updateLocation(v); _next(); });
      case 6:
        return RegisterPage7(onComplete: (sel) { p.updateSurvey(sel); _submit(p); });
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const total = 7;
    return ChangeNotifierProvider(
      create: (_) => RegistrationProvider(),
      child: Consumer<RegistrationProvider>(
        builder: (context, p, _) {
          return Stack(
            children: [
              Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / total,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF4263EB),
                          minHeight: 6,
                        ),
                      ),
                      Expanded(
                        child: PageTransitionSwitcher(
                          duration: const Duration(milliseconds: 280),
                          reverse: _reverse,
                          transitionBuilder: (child, primary, secondary) =>
                              FadeThroughTransition(animation: primary, secondaryAnimation: secondary, child: child),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _buildStep(_step, p),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
            ],
          );
        },
      ),
    );
  }
}
