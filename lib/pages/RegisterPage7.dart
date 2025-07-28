import 'package:flutter/material.dart';

class RegisterPage7 extends StatefulWidget {
  /// 마지막 선택된 옵션들을 전달할 콜백
  final void Function(Map<String, List<String>> selections) onComplete;

  const RegisterPage7({
    super.key,
    required this.onComplete,
  });

  @override
  State<RegisterPage7> createState() => _RegisterPage7State();
}

class _RegisterPage7State extends State<RegisterPage7> {
  // 카테고리::옵션 형태의 고유 키를 저장
  final Set<String> selectedKeys = {};
  // 단일 선택 처리할 카테고리
  final Set<String> singleSelectCategories = {'혼인 여부','최종 학력', '전공'};

  Widget buildOption(String category, String title) {
    final key = '$category::$title';
    final isSelected = selectedKeys.contains(key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (singleSelectCategories.contains(category)) {
            // 단일 선택 모드
            if (isSelected) {
              // 이미 선택된 항목은 해제
              selectedKeys.remove(key);
            } else {
              // 같은 카테고리 내 다른 키들 제거 후 새로 선택
              selectedKeys.removeWhere((k) => k.startsWith('$category::'));
              selectedKeys.add(key);
            }
          } else {
            // 다중 선택 모드
            if (isSelected) {
              selectedKeys.remove(key);
            } else {
              selectedKeys.add(key);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4263EB) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildCategory(String category, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          children: options.map((opt) => buildOption(category, opt)).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 목록은 스크롤 가능하도록 Expanded + SingleChildScrollView 사용
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCategory('혼인 여부', ['기혼', '미혼']),
                      buildCategory('최종 학력', ['고졸 미만', '고교 재학', '고교 졸업', '대학 재학', '대졸 예정', '대학 졸업', '대학 석/박사']),
                      buildCategory('전공', ['인문계열', '사회계열', '상경계열', '이학계열', '공학계열', '예체능계열', '농산업계열', '기타']),
                      buildCategory('취업상태', ['재직자', '자영업자', '미취업자', '프리랜서', '일용근로자', '(예비)창업자', '단기근로자', '영농종사자', '기타']),
                      buildCategory('특화분야', ['중소기업', '여성', '기초생활수급자', '한부모가정', '장애인', '농업인', '군인', '지역인재', '기타']),
                      buildCategory('관심분야', [
                        '대출', '보조금', '바우처', '금리혜택', '교육지원', '맞춤형상담서비스',
                        '인턴', '벤처', '중소기업', '청년가장', '장기미취업청년', '공공임대주택',
                        '신용회복', '육아', '출산', '해외진출', '주거지원',
                      ]),
                    ],
                  ),
                ),
              ),
              // 완료 버튼 고정
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4263EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // key = "카테고리::옵션"
                    final Map<String, List<String>> sel = {};
                    for (var key in selectedKeys) {
                      final parts = key.split('::');
                      final category = parts[0];
                      final title    = parts[1];
                      sel.putIfAbsent(category, () => []).add(title);
                    }
                    widget.onComplete(sel);
                  },

                  child: const Text(
                    '완료',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
