import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './config.dart';

class PolicyReviewPage extends StatefulWidget {
  final int policyId;
  const PolicyReviewPage({super.key, required this.policyId});

  @override
  State<PolicyReviewPage> createState() => _PolicyReviewPageState();
}

class _PolicyReviewPageState extends State<PolicyReviewPage> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.get(
      Uri.parse('$baseUrl/api/policies/${widget.policyId}/reviews'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('후기 불러오기 실패: ${res.statusCode}');
    }
  }

  Future<void> _addReview(double rating, String content) async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.post(
      Uri.parse('$baseUrl/api/policies/${widget.policyId}/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rating': rating, 'content': content}),
    );

    if (res.statusCode == 200) {
      setState(() {
        _reviewsFuture = _fetchReviews();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('후기 작성 실패')));
    }
  }

  void _showReviewDialog() {
    double selectedRating = 3.0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("후기 작성"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedRating = (i + 1).toDouble();
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "후기를 작성해주세요",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              _addReview(selectedRating, controller.text);
              Navigator.pop(context);
            },
            child: const Text("등록"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '정책 후기',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showReviewDialog),
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reviewsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('에러: ${snap.error}'));
          }

          final reviews = snap.data ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text("아직 작성된 후기가 없습니다."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final review = reviews[i];
              final author = review['author'] ?? "익명";
              final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
              final content = review['content'] ?? "";

              return Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          author,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (j) {
                            return Icon(
                              j < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
