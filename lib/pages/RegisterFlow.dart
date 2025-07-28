import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:animations/animations.dart';
import 'RegisterPage1.dart';
import 'RegisterPage2.dart';
import 'RegisterPage3.dart';
import 'RegisterPage4.dart';
import 'RegisterPage5.dart';
import 'RegisterPage6.dart';
import 'RegisterPage7.dart';
import 'Success.dart';

import 'config.dart';

class RegisterState {
  String? email;
  String? nickname;
  String? password;
  DateTime? birthDate;
  String? location;
  String? income;

  // single‑value fields
  String  maritalStatus = '';
  String  education     = '';
  String  major         = '';

  // multi‑value fields
  List<String> employmentStatus = [];   // NEW
  List<String> specialGroup     = [];
  List<String> interests        = [];
}

class RegisterFlow extends StatefulWidget {
  const RegisterFlow({super.key});

  @override
  State<RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<RegisterFlow> {
  final _state = RegisterState();
  int _step = 0;
  bool _reverse = false;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final body = _buildSignupBody(_state);
      final resp = await http
          .post(
        Uri.parse('$baseUrl/api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('>>> REQUEST: ${jsonEncode(body)}');
      debugPrint('<<< RESPONSE: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 201) {
        final json = jsonDecode(resp.body);
        final nickname = json['nickname'] as String;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClapAnimationPage(mode: 0, nickname: nickname),
          ),
        );
        return;
      }

      // 그 외 상태코드
      _showSnack('회원가입 실패 (${resp.statusCode}) - ${resp.body}');
    } catch (e) {
      _showSnack('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final v = jsonDecode(body);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return {};
  }

  Map<String, dynamic> _buildSignupBody(RegisterState s) {
    return {
      "email"            : s.email          ?? '',
      "nickname"         : s.nickname       ?? '',
      "password"         : s.password       ?? '',
      "birthDate"        : s.birthDate != null
          ? s.birthDate!.toIso8601String().split('T')[0]
          : '2000-01-01',
      "location"         : s.location       ?? '서울특별시 강남구',
      "income"           : s.income         ?? '0',
      "maritalStatus"    : s.maritalStatus,
      "education"        : s.education,
      "major"            : s.major,
      "employmentStatus" : s.employmentStatus,      // NEW
      "specialGroup"     : s.specialGroup,
      "interests"        : s.interests,
    };
  }


  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _next() {
    setState(() {
      _reverse = false;
      _step++;
    });
  }

  void _prev() {
    if (_step == 0) return;
    setState(() {
      _reverse = true;
      _step--;
    });
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return RegisterPage1(onNext: (v) {
          _state.email = v;
          _next();
        });
      case 1:
        return RegisterPage2(onNext: (v) {
          _state.nickname = v;
          _next();
        });
      case 2:
        return RegisterPage3(onNext: (v) {
          _state.password = v;
          _next();
        });
      case 3:
        return RegisterPage4(onNext: (v) {
          _state.birthDate = v;
          _next();
        });
      case 4:
        return RegisterPage5(onNext: (v) {
          _state.income = v;
          _next();
        });
      case 5:
        return RegisterPage6(onComplete: (v) {
          _state.location = v;
          _next();
        });
      case 6:
        return RegisterPage7(onComplete: (selections) {
          setState(() {
            // '혼인 여부'는 single-select이니 첫 번째 값
            _state.maritalStatus  = selections['혼인 여부']?.first  ?? '';
            _state.education      = selections['최종 학력']?.first  ?? '';
            _state.major          = selections['전공']?.first      ?? '';

            // 다중 선택 카테고리
            _state.specialGroup   = selections['특화분야']        ?? [];
            _state.interests      = selections['관심분야']        ?? [];

            // (기존 태그 네이밍을 interests로 바꿨다면 _state.interests)
          });
          _submit();
        });
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const total = 7;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    transitionBuilder: (child, primary, secondary) {
                      return FadeThroughTransition(
                        animation: primary,
                        secondaryAnimation: secondary,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(_step),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
