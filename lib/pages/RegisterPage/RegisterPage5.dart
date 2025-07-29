import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisterPage5 extends StatefulWidget {
  final void Function(String income) onNext;

  const RegisterPage5({
    super.key,
    required this.onNext,
  });

  @override
  State<RegisterPage5> createState() => _RegisterPage5State();
}

class _RegisterPage5State extends State<RegisterPage5> {
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###'); // 1,000,000 포맷

  void _onChanged(String value) {
    final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.isEmpty) {
      _controller.clear();
      return;
    }

    final formatted = _formatter.format(int.parse(numeric));
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
                '연 소득을 알려주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₩ ',
                  hintText: '예: 30,000,000',
                  border: UnderlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 300),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final rawNumeric = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                    widget.onNext(rawNumeric); // 정제된 숫자만 넘김 (ex: '30000000')
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
