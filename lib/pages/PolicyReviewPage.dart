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
  String? myEmail;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchReviews();
    _loadMyEmail();
  }

  Future<void> _loadMyEmail() async {
    myEmail = await _storage.read(key: 'user_email');
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.get(
      Uri.parse('$baseUrl/api/policies/${widget.policyId}/reviews'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      throw Exception('후기 불러오기 실패: ${res.statusCode}');
    }
  }

  Future<void> _addOrUpdateReview(double rating, String content) async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.post(
      Uri.parse('$baseUrl/api/policies/${widget.policyId}/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rating': rating, 'content': content}),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      setState(() {
        _reviewsFuture = _fetchReviews();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('후기 작성 실패')));
    }
  }

  Future<void> _deleteReview() async {
    final token = await _storage.read(key: 'access_token');
    final res = await http.delete(
      Uri.parse('$baseUrl/api/policies/${widget.policyId}/reviews'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      setState(() {
        _reviewsFuture = _fetchReviews();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 삭제 실패')));
    }
  }

  Future<void> _openReviewDialog() async {
    final reviews = await _fetchReviews();
    final myReview = reviews.firstWhere(
      (r) => r['author_email'] == myEmail,
      orElse: () => {},
    );

    if (myReview.isNotEmpty) {
      _showReviewDialog(
        initialRating: (myReview['rating'] as num?)?.toDouble() ?? 5,
        initialContent: myReview['content'] ?? "",
        isEdit: true,
      );
    } else {
      _showReviewDialog(isEdit: false);
    }
  }

  void _showReviewDialog({
    double initialRating = 5,
    String initialContent = "",
    bool isEdit = false,
  }) {
    double selectedRating = initialRating;
    final controller = TextEditingController(text: initialContent);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? "후기 수정" : "후기 작성",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            setDialogState(() {
                              selectedRating = (i + 1).toDouble();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "후기를 작성해주세요",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Colors.black26,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "취소",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              _addOrUpdateReview(
                                selectedRating,
                                controller.text,
                              );
                              Navigator.pop(context);
                            },
                            child: Text(
                              isEdit ? "수정" : "등록",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '정책 후기',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _openReviewDialog,
          ),
        ],
      ),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "아직 작성된 후기가 없습니다.",
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "새로운 후기를 작성해보세요!",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final review = reviews[i];
              final author = review['nickname'] ?? "익명";
              final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
              final content = review['content'] ?? "";

              final isMine =
                  myEmail?.trim() == review['author_email']?.toString().trim();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
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
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (j) {
                            return Icon(
                              j < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(fontSize: 14)),
                    if (isMine) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: _deleteReview,
                          child: const Padding(
                            padding: EdgeInsets.only(
                              top: 6,
                              bottom: 6,
                              left: 6,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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
