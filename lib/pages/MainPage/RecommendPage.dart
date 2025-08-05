import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
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
  List<Map<String, dynamic>> _results = [];

  Future<void> _fetchRecommendations() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프롬프트를 입력하세요.')));
      return;
    }

    setState(() => _loading = true);

    try {
      final token = await _storage.read(key: 'access_token');
      final uri = Uri.parse(
        '$baseUrl/api/policies/recommend',
      ).replace(queryParameters: {'prompt': prompt});

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<Map<String, dynamic>> parsed =
            List<Map<String, dynamic>>.from(data['recommendations']);
        setState(() => _results = parsed);
      } else {
        throw Exception('추천 실패: ${res.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _resultItem(Map<String, dynamic> policy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 0.5,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ListTile(
          dense: true,
          title: Text(
            policy['plcyNm'] ?? '정책명 없음',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PolicyDetailPage(policyId: policy['id']),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('맞춤 정책 추천')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _promptCtrl,
              decoration: const InputDecoration(
                labelText: '프롬프트',
                hintText: '예) 주거‧창업 관련 정책 알려줘',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _fetchRecommendations,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('추천 받기'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('추천 결과가 없습니다.'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _resultItem(_results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
