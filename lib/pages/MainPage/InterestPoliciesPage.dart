import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import '../PolicyDetailPage.dart';

class InterestPoliciesPage extends StatefulWidget {
  const InterestPoliciesPage({super.key});

  @override
  State<InterestPoliciesPage> createState() => _InterestPoliciesPageState();
}

class _InterestPoliciesPageState extends State<InterestPoliciesPage> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Map<String, dynamic>>> _likesFuture;

  @override
  void initState() {
    super.initState();
    _likesFuture = _fetchLikedPolicies();
  }

  Future<List<Map<String, dynamic>>> _fetchLikedPolicies() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.get(
      Uri.parse('$baseUrl/api/mypage/likes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('관심 정책 불러오기 실패: ${res.statusCode}');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _likesFuture = _fetchLikedPolicies();
    });
    await _likesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '나의 관심 정책',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _likesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('오류: ${snap.error}'));
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('관심 정책이 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final policy = items[i];
                final id = policy['id'];
                final title = (policy['plcyNm'] ?? '제목 없음').toString();

                return Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: id == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PolicyDetailPage(policyId: id),
                              ),
                            );
                          },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      dense: true,
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
