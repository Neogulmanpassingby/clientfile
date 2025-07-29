import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../config.dart';

final String apiBase = const String.fromEnvironment('API_BASE', defaultValue: baseUrl);

// 시·도 목록
const Map<String, List<String>> _sidoSigungu = {
  '서울특별시': [],  '부산광역시': [],  '대구광역시': [],  '인천광역시': [],
  '광주광역시': [],  '대전광역시': [],  '울산광역시': [],  '세종특별자치시': [],
  '경기도': [],      '강원도': [],      '충청북도': [],    '충청남도': [],
  '전라북도': [],    '전라남도': [],    '경상북도': [],    '경상남도': [],
  '제주특별자치도': [],
};

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // ───────────── 상태
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  List<String> _results = [];

  // 빠른 필터
  String? _selectedSido;
  String? _selectedEmploymentStatus;

  // 상세 필터
  String? _maritalStatus;
  String? _education;
  String? _major;
  final Set<String> _specialGroups = {};
  final Set<String> _interests     = {};

  // 리스트
  late final List<String> _sidoList = ['전국', ..._sidoSigungu.keys];
  final _employmentStatuses = [
    '재직자', '자영업자', '미취업자', '프리랜서',
    '일용근로자', '(예비)창업자', '단기근로자', '영농종사자', '기타'
  ];

  // ───────────── 디바운스 입력
  void _onSearchChanged(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  // ───────────── API 호출
  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);

    final uri = Uri.parse('$apiBase/api/policies/search').replace(queryParameters: {
      'q': q,
      if (_selectedSido != null)                'sido'            : _selectedSido!,
      if (_selectedEmploymentStatus != null)    'employmentStatus': _selectedEmploymentStatus!,
      if (_maritalStatus != null)               'maritalStatus'   : _maritalStatus!,
      if (_education != null)                   'education'       : _education!,
      if (_major != null)                       'major'           : _major!,
      if (_specialGroups.isNotEmpty)            'specialGroup'    : _specialGroups.join(','),
      if (_interests.isNotEmpty)                'interests'       : _interests.join(','),
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        setState(() =>
        _results = (jsonDecode(res.body) as List).cast<String>());
      } else {
        setState(() => _results = []);
      }
    } catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ───────────── Shimmer (로딩 카드)
  Widget _shimmer() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  // ───────────── 검색바 (토스 카드형)
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        elevation: 0.5,
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 14),
            prefixIcon: Icon(Icons.search, size: 22),
            hintText: '검색어를 입력하세요',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ───────────── Quick Filter Pills
  Widget _quickFilters() {
    final chips = <Widget>[
      ActionChip(
        label: Text(_selectedSido ?? '시·도'),
        onPressed: _openSidoPicker,
      ),
      ActionChip(
        label: Text(_selectedEmploymentStatus ?? '취업상태'),
        onPressed: _openEmploymentPicker,
      ),
      ActionChip(
        avatar: const Icon(Icons.tune, size: 18),
        label: const Text('필터 ·'),
        onPressed: _openDetailFilter,
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => chips[i],
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }

  // ───────────── 결과 카드 (토스 스타일)
  Widget _resultItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 0.5,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ListTile(
          dense: true,
          title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {}, // TODO: 상세 페이지 이동
        ),
      ),
    );
  }

  // ───────────── 시·도 BottomSheet
  Future<void> _openSidoPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        children: _sidoList
            .map((s) => ListTile(
          title: Text(s),
          onTap: () => Navigator.pop(context, s == '전국' ? null : s),
        ))
            .toList(),
      ),
    );
    if (selected != null || (selected == null && _selectedSido != null)) {
      setState(() => _selectedSido = selected);
      _search(_controller.text);
    }
  }

  // ───────────── 취업상태 BottomSheet
  Future<void> _openEmploymentPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        children: _employmentStatuses
            .map((e) =>
            ListTile(title: Text(e), onTap: () => Navigator.pop(context, e)))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() => _selectedEmploymentStatus = selected);
      _search(_controller.text);
    }
  }

  // ───────────── 상세 필터 BottomSheet (기존 로직 재활용)
  void _openDetailFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) {
          void toggleSingle(String title, String? value) {
            setModal(() {
              setState(() {
                switch (title) {
                  case '혼인 여부': _maritalStatus = value; break;
                  case '최종 학력': _education     = value; break;
                  case '전공':     _major         = value; break;
                }
              });
            });
          }

          void toggleMulti(Set<String> target, String value) {
            setModal(() {
              setState(() {
                target.contains(value)
                    ? target.remove(value)
                    : target.add(value);
              });
            });
          }

          Widget buildCategory(
              String title,
              List<String> items, {
                bool multi = false,
              }) {
            const accent = Color(0xFF0064FF); // 토스 블루

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Wrap(
                  spacing: 6,
                  children: items.map((e) {
                    bool selected = false;
                    switch (title) {
                      case '혼인 여부': selected = _maritalStatus == e; break;
                      case '최종 학력': selected = _education == e; break;
                      case '전공':     selected = _major == e; break;
                      case '특화분야': selected = _specialGroups.contains(e); break;
                      case '관심분야': selected = _interests.contains(e); break;
                    }

                    return FilterChip(
                      showCheckmark: false,
                      selectedColor: accent.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: selected ? accent : Colors.black87,
                        fontSize: 13,
                      ),
                      label: Text(e),
                      selected: selected,
                      onSelected: (_) {
                        if (multi) {
                          title == '특화분야'
                              ? toggleMulti(_specialGroups, e)
                              : toggleMulti(_interests, e);
                        } else {
                          toggleSingle(title, selected ? null : e);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          }


          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildCategory('혼인 여부', ['기혼', '미혼']),
                  buildCategory('최종 학력', [
                    '고졸 미만','고교 재학','고교 졸업','대학 재학',
                    '대졸 예정','대학 졸업','대학 석/박사'
                  ]),
                  buildCategory('전공', [
                    '인문계열','사회계열','상경계열','이학계열',
                    '공학계열','예체능계열','농산업계열','기타'
                  ]),
                  buildCategory('특화분야', [
                    '중소기업','여성','기초생활수급자','한부모가정','장애인',
                    '농업인','군인','지역인재','기타'
                  ], multi: true),
                  buildCategory('관심분야', [
                    '대출','보조금','바우처','금리혜택','교육지원','맞춤형상담서비스',
                    '인턴','벤처','중소기업','청년가장','장기미취업청년','공공임대주택',
                    '신용회복','육아','출산','해외진출','주거지원'
                  ], multi: true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _search(_controller.text);
                    },
                    child: const Text('적용'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────── UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('검색', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _searchBar(),
          _quickFilters(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => _shimmer(),
            )
                : _results.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) => _resultItem(_results[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── 메모리 정리
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
