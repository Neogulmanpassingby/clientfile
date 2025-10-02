import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/config.dart';
import '../PolicyDetailPage.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final _storage = const FlutterSecureStorage();
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _results = [];
  int? _recommendCount; // ★ 1. 남은 추천 횟수를 저장할 변수 추가

  // ★ 2. 페이지가 처음 로드될 때 실행되는 initState 추가
  @override
  void initState() {
    super.initState();
    // 위젯이 빌드되자마자 남은 횟수를 서버에서 가져옴
    _fetchRecommendCount();
  }

  // ★ 3. 남은 추천 횟수를 가져오는 함수 추가
  Future<void> _fetchRecommendCount() async {
    try {
      final token = await _storage.read(key: 'access_token');
      // 이전 단계에서 만든 API 엔드포인트 호출
      final uri = Uri.parse('$baseUrl/api/mypage/recommend');

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          // 'recommendCount' 값을 변수에 저장
          _recommendCount = data['recommendCount'];
        });
      } else {
        // 에러 발생 시 횟수를 0으로 설정
        setState(() => _recommendCount = 0);
      }
    } catch (e) {
      // 예외 발생 시 횟수를 0으로 설정
      setState(() => _recommendCount = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추천 횟수를 불러오는 데 실패했습니다.')),
      );
    }
  }

  Future<void> _fetchRecommendations() async {
    // ★ 4. 추천 받기 전, 횟수 확인 로직 추가
    if (_recommendCount != null && _recommendCount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추천 횟수를 모두 사용했습니다.')),
      );
      return; // 함수 실행 중단
    }

    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프롬프트를 입력하세요.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final uri = Uri.parse('$baseUrl/api/policies/recommend')
          .replace(queryParameters: {'prompt': prompt});

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<Map<String, dynamic>> parsed =
        List<Map<String, dynamic>>.from(data['recommendations']);
        setState(() {
          _results = parsed;
          // ★ 5. 추천 성공 시, 화면의 횟수를 1 감소시켜 즉시 반영
          if (_recommendCount != null) {
            _recommendCount = _recommendCount! - 1;
          }
        });
      } else {
        // 서버에서 429 Too Many Requests 같은 상태 코드를 보낼 경우 처리
        if (res.statusCode == 429) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('추천 횟수를 초과했습니다.')),
          );
        } else {
          throw Exception('추천 실패: ${res.statusCode}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ... _resultItem 위젯은 변경 없음 ...
  Widget _resultItem(Map<String, dynamic> policy) {
    final title = (policy['plcyNm'] ?? '정책명 없음').toString();
    final reason = (policy['reason'] ?? '').toString();
    final List<String> badges = (policy['badges'] is List)
        ? List<String>.from((policy['badges'] as List).map((e) => e.toString()))
        : const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PolicyDetailPage(policyId: policy['id']),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E8EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (reason.isNotEmpty || badges.isNotEmpty)
                      const SizedBox(height: 6),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: -8,
                        children: badges
                            .take(6)
                            .map(
                              (b) => Chip(
                            label: Text(b),
                            backgroundColor: const Color(0xFFF1F3F5),
                            labelStyle: const TextStyle(fontSize: 12),
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '맞춤 정책 추천',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // ... TextField 부분은 변경 없음 ...
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E8EB)),
              ),
              child: TextField(
                controller: _promptCtrl,
                decoration: const InputDecoration(
                  labelText: '프롬프트',
                  hintText: '예) 주거‧창업 관련 정책 알려줘',
                  hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                  border: InputBorder.none,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loading ? null : _fetchRecommendations,
                child: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  '추천 받기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ★ 6. 남은 횟수 표시 위젯 추가
          if (_recommendCount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                '남은 추천 횟수: $_recommendCount회',
                style: TextStyle(
                  color: _recommendCount! > 0 ? Colors.blueGrey : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (!_hasSearched
                ? const Center(
              child: Text(
                '프롬프트를 입력하고 [추천 받기]를 눌러보세요.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : (_results.isEmpty
                ? const Center(
              child: Text(
                '추천 결과가 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) => _resultItem(_results[i]),
            ))),
          )
        ],
      ),
    );
  }
}