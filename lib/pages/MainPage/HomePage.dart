import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'recommend_page.dart';
import '../PolicyDetailPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Map<String, dynamic>>> _popularFuture;
  late Future<List<Map<String, dynamic>>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _popularFuture = _fetchPopularPolicies();
    _recentFuture = _fetchRecentPolicies();
  }

  Future<List<Map<String, dynamic>>> _fetchPopularPolicies() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.get(
      Uri.parse('$baseUrl/api/policies/popular'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('인기 정책 불러오기 실패: ${res.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentPolicies() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.get(
      Uri.parse('$baseUrl/api/policies/recent'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('최근 정책 불러오기 실패: ${res.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정책지대')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _recentFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snap.hasError) {
                  return Text('최신 정책 에러: ${snap.error}');
                } else {
                  final policies = snap.data!;
                  return _PolicyCard(title: '최신 정책', policyList: policies);
                }
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _popularFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snap.hasError) {
                  return Text('인기 정책 에러: ${snap.error}');
                } else {
                  final policies = snap.data!;
                  return _PolicyCard(title: '인기 정책', policyList: policies);
                }
              },
            ),
            const SizedBox(height: 16),

            // ── 맞춤 정책 추천 카드
            _ActionCard(
              title: '나를 위한 맞춤 정책',
              subtitle: '프롬프트를 입력해 맞춤 추천 받기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecommendPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> policyList;

  const _PolicyCard({required this.title, required this.policyList});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...policyList.map(
              (policy) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(policy['plcyNm']),
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
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
