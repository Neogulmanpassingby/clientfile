import 'package:flutter/material.dart';

class RegisterPage2 extends StatefulWidget {
  final void Function(String nickname) onNext;

  const RegisterPage2({
    super.key,
    required this.onNext,
  });

  @override
  State<RegisterPage2> createState() => _RegisterPage2State();
}

class _RegisterPage2State extends State<RegisterPage2>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // 간단한 하드코딩 금칙어 (실서비스는 외부 리소스/정규화 권장)
  static const Set<String> _blacklist = {
    'fuck', 'shit', 'bitch', 'asshole', 'bastard',
    '씨발', '병신', '지랄', '개새', '좆', '씹', '개년', '육시랄',
  };

  bool _showError = false; // blur/submit 때만 true
  bool _isValid = false;   // 내부적으로만 사용 (버튼은 항상 enable)

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

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

  bool _containsProfanity(String text) {
    final lowered = text.toLowerCase();
    for (final w in _blacklist) {
      if (lowered.contains(w.toLowerCase())) return true;
    }
    return false;
  }

  bool _isNicknameValid(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (_containsProfanity(t)) return false;
    // 필요하면 길이/문자셋 등 추가
    return true;
  }

  void _validate({bool showMessage = false, bool shakeIfError = false}) {
    final ok = _isNicknameValid(_controller.text);
    setState(() {
      _isValid = ok;
      if (showMessage) _showError = !ok;
    });
    if (shakeIfError && !ok) {
      _shakeController.forward(from: 0);
    }
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
                '별명을 알려주세요',
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
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: '닉네임을 입력하세요',
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFF4263EB),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    // 입력 중엔 메시지 숨기고(토스 스타일), 내부 valid만 갱신
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
                    '욕설이 포함되어 있어요. 다른 별명을 입력해 주세요.',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 300),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // 항상 활성화
                  onPressed: () {
                    _validate(showMessage: true, shakeIfError: true);
                    if (_isValid) {
                      widget.onNext(_controller.text.trim());
                    }
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
