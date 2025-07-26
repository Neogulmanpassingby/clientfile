import 'package:flutter/material.dart';
<<<<<<< HEAD:lib/pages/RegisterPage/RegisterPage5.dart
import 'package:intl/intl.dart';

class RegisterPage5 extends StatefulWidget {
  final void Function(String income) onNext;

  const RegisterPage5({
=======
import 'package:flutter/services.dart';

class RegisterPage1 extends StatefulWidget {
  final void Function(String email) onNext;

  const RegisterPage1({
>>>>>>> 5187ed4 (my first commit):lib/pages/RegisterPage1.dart
    super.key,
    required this.onNext,
  });

  @override
<<<<<<< HEAD:lib/pages/RegisterPage/RegisterPage5.dart
  State<RegisterPage5> createState() => _RegisterPage5State();
}

class _RegisterPage5State extends State<RegisterPage5> {
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###'); // 1,000,000 포맷

  void _onChanged(String value) {
    // 숫자만 추출
    final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.isEmpty) {
      _controller.clear();
      return;
    }

    // 콤마 포맷 적용
    final formatted = _formatter.format(int.parse(numeric));
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
=======
  State<RegisterPage1> createState() => _RegisterPage1State();
}

/// 모든(유니코드) 공백을 제거
class NoWhitespaceFormatter extends TextInputFormatter {
  static final _re = RegExp(
    r'[\s\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF]',
  );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final filtered = newValue.text.replaceAll(_re, '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
      composing: TextRange.empty,
    );
  }
}

class _RegisterPage1State extends State<RegisterPage1>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _showError = false; // blur/submit 에서만 true
  bool _isValid = false;   // 내부적으로만 쓰고, 버튼은 항상 enable

  // '@domain.tld' 형태를 강제(서브도메인 허용)
  final _emailRe = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$",
  );

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  bool _isValidEmail(String v) => _emailRe.hasMatch(v.trim());

  void _validate({bool showMessage = false, bool shakeIfError = false}) {
    final text = _controller.text.trim();
    final ok = _isValidEmail(text);
    setState(() {
      _isValid = ok;
      if (showMessage) _showError = text.isNotEmpty && !ok;
    });
    if (shakeIfError && !ok) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validate(showMessage: true, shakeIfError: true);
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
>>>>>>> 5187ed4 (my first commit):lib/pages/RegisterPage1.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          reverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
              const Text(
<<<<<<< HEAD:lib/pages/RegisterPage/RegisterPage5.dart
                '연 소득을 알려주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₩ ', // 앞에 원화 기호 붙임
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
=======
                '이메일을 알려주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  inputFormatters: [NoWhitespaceFormatter()],
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    hintText: '이메일 입력',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFF4263EB),
                        width: 2,
                      ),
                    ),
>>>>>>> 5187ed4 (my first commit):lib/pages/RegisterPage1.dart
                  ),
                  onChanged: (v) {
                    // 입력 중엔 메시지 숨김 (토스 스타일), 내부 valid만 갱신
                    _showError = false;
                    _validate(showMessage: false, shakeIfError: false);
                  },
                  onEditingComplete: () {
                    _validate(showMessage: true, shakeIfError: true);
                    FocusScope.of(context).unfocus();
                  },
                ),
                onChanged: _onChanged, // 콤마 포맷 적용
              ),
<<<<<<< HEAD:lib/pages/RegisterPage/RegisterPage5.dart
              const SizedBox(height: 300),
=======

              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '이메일 형식이 올바르지 않아요.',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 300),

>>>>>>> 5187ed4 (my first commit):lib/pages/RegisterPage1.dart
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // 항상 활성화
                  onPressed: () {
<<<<<<< HEAD:lib/pages/RegisterPage/RegisterPage5.dart
                    widget.onNext(_controller.text);
=======
                    _validate(showMessage: true, shakeIfError: true);
                    if (_isValid) {
                      widget.onNext(_controller.text.trim());
                    }
>>>>>>> 5187ed4 (my first commit):lib/pages/RegisterPage1.dart
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4263EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 22,
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
