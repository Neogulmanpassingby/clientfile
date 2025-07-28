import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Success.dart'; // ClapAnimationPage 정의
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

// 환경변수 우선, 없으면 config.dart의 baseUrl 사용
const String apiBase =
String.fromEnvironment('API_BASE', defaultValue: baseUrl);

// secure storage 인스턴스
final _storage = FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// ─────────────────────────────────────────────────────────────────
///  ShakingTextFormField : 잘못된 입력 시 좌우로 흔들리는 TextFormField
///  - validator에서 에러가 나면 자동으로 shake()
///  - TextFormField 자체 errorText는 숨김(errorStyle.height = 0)
/// ─────────────────────────────────────────────────────────────────
class ShakingTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  const ShakingTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
    this.focusNode,
  });

  @override
  State<ShakingTextFormField> createState() => _ShakingTextFormFieldState();
}

class _ShakingTextFormFieldState extends State<ShakingTextFormField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetX;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _offsetX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _wrappedValidator(String? v) {
    final res = widget.validator?.call(v);
    if (res != null) {
      // validator 실패 시 흔들림
      shake();
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetX,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetX.value, 0),
          child: TextFormField(
            focusNode: widget.focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: _wrappedValidator,
            decoration: InputDecoration(
              labelText: widget.label,
              suffixIcon: widget.suffixIcon,
              errorStyle: const TextStyle(height: 0, fontSize: 0),

              // 기본/포커스 보더도 명시해서 테마 영향 배제
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4263EB), width: 1.4),
              ),

              // 🔴 에러일 때 보더
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.2),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.4),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ─────────────────────────────────────────────────────────────────
///  LoginPage
/// ─────────────────────────────────────────────────────────────────
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  final _emailFieldKey = GlobalKey<_ShakingTextFormFieldState>();
  final _pwFieldKey = GlobalKey<_ShakingTextFormFieldState>();

  final _emailFocus = FocusNode();
  final _pwFocus = FocusNode();

  String? _globalError;

  bool _isLoading = false;
  bool _obscurePw = true;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  /// 클라이언트 사이드 밸리데이션
  bool _validate() {
    _globalError = null;

    // validator들이 실행된다. (에러 텍스트는 숨기지만, 실패 여부는 bool로 리턴)
    final ok = _formKey.currentState?.validate() ?? false;

    if (!ok) {
      // Form validator에서 위젯이 알아서 흔들림 (ShakingTextFormField 내부)
      // 사용자에게는 하나의 문구만 보여준다.
      setState(() {
        _globalError = '입력한 정보를 다시 확인해주세요';
      });
    }

    return ok;
  }

  Future<void> _saveToken(Map<String, dynamic> json) async {
    final accessToken = json['token'] as String?;
    final refreshToken = json['refresh_token'] as String?;
    final expiresIn = json['expires_in'] as int?;

    if (accessToken != null) {
      await _storage.write(key: 'access_token', value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    if (expiresIn != null) {
      final expiryAt =
      DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      await _storage.write(key: 'access_token_exp', value: expiryAt);
    }
  }

  Future<void> _login() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _globalError = null; // 제출 직전엔 초기화
    });

    try {
      final email = _emailController.text.trim();
      final password = _pwController.text;

      final resp = await http.post(
        Uri.parse('$apiBase/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final nickname = json['nickname'] as String? ?? '';

        await _saveToken(json);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClapAnimationPage(mode: 1, nickname: nickname),
          ),
        );
      } else if (resp.statusCode == 401) {
        // 서버 인증 실패 → 두 필드 모두 흔들기 + 공통 에러
        _emailFieldKey.currentState?.shake();
        _pwFieldKey.currentState?.shake();
        setState(() {
          _globalError = '이메일 또는 비밀번호가 올바르지 않아요.';
        });
      } else {
        setState(() {
          _globalError = '로그인 실패 (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _globalError = '네트워크 오류: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'empty';
    if (!value.contains('@')) return 'invalid';
    return null;
  }

  String? _passwordValidator(String? v) {
    final value = (v ?? '');
    if (value.length < 6) return 'short';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          padding: EdgeInsets.fromLTRB(
            16,
            32,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShakingTextFormField(
                  key: _emailFieldKey,
                  focusNode: _emailFocus,
                  controller: _emailController,
                  label: '이메일',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _pwFocus.requestFocus(),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 12),
                ShakingTextFormField(
                  key: _pwFieldKey,
                  focusNode: _pwFocus,
                  controller: _pwController,
                  label: '비밀번호',
                  obscureText: _obscurePw,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: _passwordValidator,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePw ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePw = !_obscurePw);
                    },
                  ),
                ),

                // ✅ 공통 에러 한 줄만 표시
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.1),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _globalError == null
                      ? const SizedBox.shrink()
                      : Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _globalError!,
                      style: const TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4263EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
