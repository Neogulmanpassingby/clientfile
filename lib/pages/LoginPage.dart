import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Success.dart'; // ClapAnimationPage 정의

const String _defaultBaseUrl = 'http://10.0.2.2:3000';

const String baseUrl =
String.fromEnvironment('API_BASE', defaultValue: _defaultBaseUrl);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePw = true;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final pw = _pwController.text;
    if (email.isEmpty || !email.contains('@')) {
      _showError('올바른 이메일을 입력하세요');
      return false;
    }
    if (pw.length < 6) {
      _showError('비밀번호는 6자 이상이어야 합니다');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _login() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _pwController.text;

      final resp = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final token = json['token'] as String;
        final nickname = json['nickname'] as String? ?? '';

        // TODO: token 저장 (secure storage 등)
        // await storage.write(key: 'token', value: token);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClapAnimationPage(mode: 1, nickname: nickname),
          ),
        );
      } else if (resp.statusCode == 401) {
        _showError('로그인 실패 (401)');
      } else {
        _showError('로그인 실패 (${resp.statusCode}) - ${resp.body}');
      }
    } catch (e) {
      _showError('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePw ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePw = !_obscurePw);
                    },
                  ),
                ),
                obscureText: _obscurePw,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 32),
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
    );
  }
}
