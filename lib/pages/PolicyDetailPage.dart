import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class PolicyDetailPage extends StatefulWidget {
  final String policyId;

  const PolicyDetailPage({super.key, required this.policyId});

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  late Future<PolicyDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = fetchPolicyDetail(widget.policyId);
  }

  Future<PolicyDetail> fetchPolicyDetail(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/policies/$id'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return PolicyDetail.fromJson(data);
    } else {
      throw Exception('정책 정보를 불러올 수 없습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정책 상세')),
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                policy.plcyNm,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
              if (policy.aplyUrlAddr.isNotEmpty)
                _section('신청 링크', policy.aplyUrlAddr),
              _section('심사 방법', policy.srngMthdCn),
              _section('제출 서류', policy.sbmsnDcmntCn),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, String content) {
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
          Text(content.isNotEmpty ? content : '정보 없음'),
        ],
      ),
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
  });

  factory PolicyDetail.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
