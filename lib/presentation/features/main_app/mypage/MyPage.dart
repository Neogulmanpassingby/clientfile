import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import '../../../../core/config.dart';
import 'package:go_router/go_router.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('로그인이 필요합니다.');

    final res = await http.get(
      Uri.parse('$baseUrl/api/mypage/basic'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('유저 정보 불러오기 실패');
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'access_token');
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!context.mounted) return;
        // 예: 마이페이지가 탭 2라면
        context.go('/main?tab=2');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            '마이페이지',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        backgroundColor: const Color(0xFFF7F8FA),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('오류 발생: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final nickname = data['nickname'] ?? '닉네임 없음';
            final email = data['email'] ?? '이메일 없음';

            final rawDate = data['birthDate'];
            final birthDate = rawDate != null
                ? DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(rawDate).toLocal())
                : '생년월일 없음';

            final location = data['location'] ?? '거주지 없음';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 프로필 카드
                _tossCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE6E8EB),
                        child: Icon(Icons.person, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 16, color: Colors.white),
                          label: const Text(
                            '로그아웃',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 4, // ✨ 은은한 그림자 (토스 느낌)
                            shadowColor: Colors.redAccent.withOpacity(0.4), // 그림자 색감 살짝
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 30), // 높이 조정
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // ✅ 둥글게
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 내 정보 카드
                _tossCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "내 정보",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow("닉네임", nickname),
                      _infoRow("생년월일", birthDate),
                      _infoRow("거주지", location),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // go('/edit') 대신
                            context.push('/edit');
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4263EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Center(
                            child: Text(
                              "내 정보 수정",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 나의 관심 정책 카드
                _tossCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.favorite,
                      color: Color(0xFF4263EB),
                    ),
                    title: const Text(
                      '나의 관심 정책',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/likes');
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tossCard({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
