import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

class PolicyDetailPage extends StatefulWidget {
  final int policyId;
  final VoidCallback? onLikeChanged;

  const PolicyDetailPage({
    super.key,
    required this.policyId,
    this.onLikeChanged,
  });

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  late Future<PolicyDetail> _detail;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _detail = fetchPolicyDetail(widget.policyId);
  }

  Future<PolicyDetail> fetchPolicyDetail(int id) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('로그인이 필요합니다.');

    final headers = {'Authorization': 'Bearer $token'};

    final responses = await Future.wait([
      http.get(Uri.parse('$baseUrl/api/policies/$id'), headers: headers),
      http.get(
        Uri.parse('$baseUrl/api/policies/$id/ratings/summary'),
        headers: headers,
      ),
    ]);

    final detailRes = responses[0];
    final ratingRes = responses[1];

    if (detailRes.statusCode == 200) {
      final detailData = jsonDecode(detailRes.body);
      Map<String, dynamic>? ratingData;

      if (ratingRes.statusCode == 200) {
        ratingData = jsonDecode(ratingRes.body);
      }

      final detail = PolicyDetail.fromJson(detailData, ratingData);
      await _checkLiked(detail.plcyNm);
      return detail;
    } else {
      throw Exception('정책 정보를 불러올 수 없습니다');
    }
  }

  // 관심 정책 여부 확인
  Future<void> _checkLiked(String policyTitle) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('$baseUrl/api/mypage/likes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      final titles = data.map((item) => item['plcyNm'] as String).toList();
      if (titles.contains(policyTitle)) {
        setState(() {
          _isLiked = true;
        });
      }
    } else {
      debugPrint('좋아요 목록 조회 실패: ${res.body}');
    }
  }

  // 관심 정책 추가
  Future<void> _addLike(String policyTitle) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final res = await http.post(
      Uri.parse('$baseUrl/api/mypage/likes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'policyTitle': policyTitle}),
    );

    if (res.statusCode == 200) {
      setState(() {
        _isLiked = true;
      });
      widget.onLikeChanged?.call();
    } else {
      debugPrint('관심 정책 추가 실패: ${res.body}');
    }
  }

  // 관심 정책 삭제
  Future<void> _removeLike(String policyTitle) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final res = await http.delete(
      Uri.parse('$baseUrl/api/mypage/likes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'policyTitle': policyTitle}),
    );

    if (res.statusCode == 200) {
      setState(() {
        _isLiked = false;
      });
      widget.onLikeChanged?.call();
    } else {
      debugPrint('관심 정책 삭제 실패: ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PolicyDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('불러오기 실패'));
          }

          final policy = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('정책 상세'),
              actions: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.star : Icons.star_border,
                    color: _isLiked ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    if (_isLiked) {
                      _removeLike(policy.plcyNm);
                    } else {
                      _addLike(policy.plcyNm);
                    }
                  },
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.plcyNm,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (policy.ratingAvg != null)
                      _buildRatingStars(policy.ratingAvg!)
                    else
                      const Text('(평점 없음)', style: TextStyle(fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 12),
                Text('${policy.lclsfNm} > ${policy.mclsfNm}'),
                Wrap(
                  spacing: 8,
                  children: policy.plcyKywdNm
                      .map((kw) => Chip(label: Text(kw)))
                      .toList(),
                ),
                const SizedBox(height: 20),
                _section('정책 설명', policy.plcyExplnCn),
                _section('지원 내용', policy.plcySprtCn),
                _section('신청 방법', policy.plcyAplyMthdCn),
                _section('신청 기간', policy.aplyYmd),
                _section(
                  '사업 기간',
                  '${policy.bizPrdBgngYmd} ~ ${policy.bizPrdEndYmd}',
                ),
                _sectionLink('신청 링크', policy.aplyUrlAddr),
                _section('심사 방법', policy.srngMthdCn),
                _section('제출 서류', policy.sbmsnDcmntCn),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title, String content) {
    final isValid = (content.trim().isNotEmpty) && content.trim() != '~';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(isValid ? content : '-'),
        ],
      ),
    );
  }

  Widget _sectionLink(String title, String url) {
    final isValid = url.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          isValid
              ? GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('링크를 열 수 없습니다.')),
                        );
                      }
                    }
                  },
                  child: Text(
                    url,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : const Text('-'),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    double floored = (rating * 2).floor() / 2.0;
    int fullStars = floored.floor();
    bool hasHalfStar = floored - fullStars >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          fullStars,
          (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
        ),
        if (hasHalfStar)
          const Icon(Icons.star_half, color: Colors.amber, size: 20),
        ...List.generate(
          emptyStars,
          (_) => const Icon(Icons.star_border, color: Colors.grey, size: 20),
        ),
        const SizedBox(width: 4),
        Text(
          '(${rating.toStringAsFixed(2)})',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}

class PolicyDetail {
  final String plcyNm;
  final String lclsfNm;
  final String mclsfNm;
  final List<String> plcyKywdNm;
  final String plcyExplnCn;
  final String plcySprtCn;
  final String plcyAplyMthdCn;
  final String aplyYmd;
  final String bizPrdBgngYmd;
  final String bizPrdEndYmd;
  final String aplyUrlAddr;
  final String srngMthdCn;
  final String sbmsnDcmntCn;

  final double? ratingAvg;
  final int ratingCount;

  PolicyDetail({
    required this.plcyNm,
    required this.lclsfNm,
    required this.mclsfNm,
    required this.plcyKywdNm,
    required this.plcyExplnCn,
    required this.plcySprtCn,
    required this.plcyAplyMthdCn,
    required this.aplyYmd,
    required this.bizPrdBgngYmd,
    required this.bizPrdEndYmd,
    required this.aplyUrlAddr,
    required this.srngMthdCn,
    required this.sbmsnDcmntCn,
    this.ratingAvg,
    this.ratingCount = 0,
  });

  factory PolicyDetail.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic>? ratingJson,
  ) {
    return PolicyDetail(
      plcyNm: json['plcyNm'] ?? '',
      lclsfNm: json['lclsfNm'] ?? '',
      mclsfNm: json['mclsfNm'] ?? '',
      plcyKywdNm: (json['plcyKywdNm'] as List?)?.cast<String>() ?? [],
      plcyExplnCn: json['plcyExplnCn'] ?? '',
      plcySprtCn: json['plcySprtCn'] ?? '',
      plcyAplyMthdCn: json['plcyAplyMthdCn'] ?? '',
      aplyYmd: json['aplyYmd'] ?? '',
      bizPrdBgngYmd: json['bizPrdBgngYmd'] ?? '',
      bizPrdEndYmd: json['bizPrdEndYmd'] ?? '',
      aplyUrlAddr: json['aplyUrlAddr'] ?? '',
      srngMthdCn: json['srngMthdCn'] ?? '',
      sbmsnDcmntCn: json['sbmsnDcmntCn'] ?? '',
      ratingAvg: (ratingJson?['rating_avg'] as num?)?.toDouble(),
      ratingCount: ratingJson?['rating_count'] ?? 0,
    );
  }
}
