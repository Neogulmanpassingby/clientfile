import 'package:flutter/material.dart';

class RegisterPage3 extends StatefulWidget {
  final void Function(String password) onNext;

  const RegisterPage3({
    super.key,
    required this.onNext,
  });

  @override
  State<RegisterPage3> createState() => _RegisterPage3State();
}

class _RegisterPage3State extends State<RegisterPage3>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _showError = false;
  bool _isValid = false;
  bool _obscure = true;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // 비밀번호 규칙: 8자 이상 + 영문자 + 숫자 + 특수문자
  final _passwordRe = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  bool _isValidPassword(String v) => _passwordRe.hasMatch(v);

  void _validate({bool showMessage = false, bool shakeIfError = false}) {
    final text = _controller.text;
    final ok = _isValidPassword(text);
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
                '비밀번호를 알려주세요',
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
                  autofocus: true,
                  obscureText: _obscure,
                  obscuringCharacter: '•',
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호 입력 (8자 이상, 특수문자 포함)',
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFF4263EB),
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onChanged: (_) {
                    _showError = false;
                    _validate(showMessage: false, shakeIfError: false);
                  },
                  onEditingComplete: () {
                    _validate(showMessage: true, shakeIfError: true);
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),

              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '비밀번호는 8자 이상이며, 영문/숫자/특수문자를 포함해야 합니다.',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 300),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _validate(showMessage: true, shakeIfError: true);
                    if (_isValid) widget.onNext(_controller.text.trim());
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
