import 'package:flutter/material.dart';
import 'package:cleanarea/data/constants/option_data.dart';
import 'package:cleanarea/data/constants/region_data.dart';
/// 시·도 → 시·군·구 → (특정 시일 경우) 행정구까지 선택하는 페이지.
/// [onComplete]에는 "시/도 시/군/구 [행정구]" 형태의 문자열이 반환됩니다.
class RegisterPage6 extends StatefulWidget {
  final void Function(String location) onComplete;
  const RegisterPage6({super.key, required this.onComplete});

  @override
  State<RegisterPage6> createState() => _RegisterPage6State();
}

class _RegisterPage6State extends State<RegisterPage6> {
  // 시·도 → 시·군·구 기본 매핑

  String? _selectedSido;
  String? _selectedSigungu;
  String? _selectedCityGu;

  @override
  Widget build(BuildContext context) {
    final List<String> sidoList = sidoSigungu.keys.toList();
    final List<String> sigunguList = _selectedSido == null
        ? []
        : sidoSigungu[_selectedSido]!;
    final List<String> cityGuList = (_selectedSigungu != null &&
        kCityGu.containsKey(_selectedSigungu))
        ? kCityGu[_selectedSigungu]!
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text('거주 위치 선택')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1단계: 시·도
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('시·도 선택'),
              value: _selectedSido,
              items: sidoList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() {
                _selectedSido = v;
                _selectedSigungu = null;
                _selectedCityGu = null;
              }),
            ),
            const SizedBox(height: 16),

            // 2단계: 시·군·구
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('시·군·구 선택'),
              value: _selectedSigungu,
              items: sigunguList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() {
                _selectedSigungu = v;
                _selectedCityGu = null;
              }),
            ),

            // 3단계: 특정 시의 경우 행정구 선택
            if (cityGuList.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('행정구 선택'),
                value: _selectedCityGu,
                items: cityGuList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCityGu = v),
              ),
            ],

            const Spacer(),

            // 완료 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF4263EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (_selectedSido != null && _selectedSigungu != null &&
                  (cityGuList.isEmpty || _selectedCityGu != null))
                  ? () {
                final loc = cityGuList.isEmpty
                    ? '$_selectedSido $_selectedSigungu'
                    : '$_selectedSido $_selectedSigungu $_selectedCityGu';
                widget.onComplete(loc);
              }
                  : null,
              child: const Text(
                '완료',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
