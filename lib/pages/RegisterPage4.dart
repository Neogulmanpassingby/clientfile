import 'package:flutter/material.dart';
import 'Success.dart';

class RegisterPage4 extends StatefulWidget {
  const RegisterPage4({super.key});

  @override
  State<RegisterPage4> createState() => _RegisterPage4State();
}

class _RegisterPage4State extends State<RegisterPage4> {
  final Set<String> selected = {};

  Widget buildOption(String title) {
    final isSelected = selected.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selected.remove(title);
          } else {
            selected.add(title);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4263EB) : Colors.grey.shade300,
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

  Widget buildCategory(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          children: options.map(buildOption).toList(),
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
              buildCategory('혼인 여부', ['기혼', '미혼']),
              buildCategory('월소득', ['0~2500', '2500~5000', '5000~7500', '7500~1억', '1억 이상']),
              buildCategory('최종 학력', ['중졸', '고졸', '대졸', '석사졸', '박사졸']),
              buildCategory('전공', ['컴공', '화공', '산공', '건환공', '조경']),
              buildCategory('관심분야', ['공부', '취업', '창업', '창업2', '창업3']),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4263EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClapAnimationPage(
                          mode: 0,              // 0 = 회원가입 완료
                          // username: '테스트',  // 필요하면 같이 넘겨
                        ),
                      ),
                    );
                  },
                  child: const Text('다음', style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 20,),
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
